# adapted from https://github.com/freelancing-god/tramampoline

require 'open-uri'

module Spree
  class PaypalWebsitePaymentsStandardNotification < ActiveRecord::Base
    SUPER_WICKED_PAYPAL_DATE_FORMAT = '%H:%M:%S %b %d, %Y %Z'
    STATUSES = {
      :success => 'VERIFIED',
      :failure => 'INVALID'
    }
    # descriptions taken from https://cms.paypal.com/us/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_html_IPNandPDTVariables
    PAYMENT_STATUSES = {
      :completed => 'Completed', # The payment has been completed, and the funds have been added successfully to your account balance.
      :created   => 'Created',   # A German ELV payment is made using Express Checkout.
      :processed => 'Processed', # A payment has been accepted.

      :pending   => 'Pending',   # The payment is pending. See pending_reason for more information.

      :denied    => 'Denied',    # You denied the payment. This happens only if the payment was previously pending because of possible reasons described for the pending_reason variable or the Fraud_Management_Filters_x variable.
      :expired   => 'Expired',   # This authorization has expired and cannot be captured.
      :failed    => 'Failed',    # The payment has failed. This happens only if the payment was made from your customer’s bank account.
      :refunded  => 'Refunded',  # You refunded the payment.
      :reversed  => 'Reversed',  # A payment was reversed due to a chargeback or other type of reversal. The funds have been removed from your account balance and returned to the buyer. The reason for the reversal is specified in the ReasonCode element.
      :voided    => 'Voided',    # This authorization has been voided.

      :canceled_reversal => 'Canceled_Reversal' # A reversal has been canceled. For example, you won a dispute with the customer, and the funds for the transaction that was reversed have been returned to you.
    }

    class TransactionFailedError < StandardError; end

    belongs_to :order, :class_name => 'Spree::Order'

    attr_accessor :request
    attr_accessible :request
    serialize :params

    def self.process(request)
      notification = create!(:request => request)

      notification.process!
      notification.legit?
    end

    def request=(request)
      @request = request

      self.params = request.params
      self.query_string = request.body.read

      self.order_id = order.id
      self.transaction_id = params['txn_id']
      self.payment_status = params['payment_status']
    end

    def original_payment
      @original_payment ||= Payment.find_by_identifier!(params['invoice'])
    end

    def payment
      @payment ||= begin
        # If the original payment has already been completed, use a new one.
        payment = original_payment.completed? ? original_payment.dup : original_payment
        # The transaction amount might differ from the payment amount.
        payment.tap { |payment| payment.update_attribute(:amount, amount) }
      end
    end

    def order
      @order ||= payment.order
    end

    def payment_method
      @payment_method ||= payment.payment_method
    end

    def process!
      payment.source = self
      payment.save!

      raise TransactionFailedError.new("Transaction failed (not legit): #{params.inspect}") unless legit?

      if pending?
        payment.pend! unless payment.pending?
      elsif completed?
        payment.complete! unless payment.complete?
      else
        raise TransactionFailedError.new("Transaction failed (not pending/completed): #{params.inspect}")
      end

      # FIXME duplication with controller
      # really? - at least that's similar how it's done with the spree_paypal_express extension (https://github.com/spree/spree_paypal_express/blob/1-3-stable/app/controllers/spree/checkout_controller_decorator.rb#L110-L111)
      unless order.state == 'complete'
        order.state = 'complete'
        # manually finalize it because that's what happens after the transition to complete in the state machine
        order.finalize!
      end
    end

    def legit?
      verified? && correct_business?
    end

    def verified?
      @verified ||= status == STATUSES[:success]
    end

    def correct_business?
      business == payment_method.preferred_business
    end

    def pending?
      payment_status == PAYMENT_STATUSES[:pending]
    end

    def completed?
      payment_status == PAYMENT_STATUSES[:completed]
    end

    def business
      params['business']
    end

    def status
      @status ||= Kernel.open(verification_url).try(:read)
    end

    def verification_signature
      params['verify_sign']
    end

    def payment_date
      params['payment_date']
    end

    def amount
      # params['auth_amount'].try(:to_d) # different for auth&capture vs. sale?
      params['mc_gross'].try(:to_d)
    end

    def currency
      params['mc_currency']
    end

    def payment_date=(date)
      return super unless date.is_a?(String)
      write_attribute(:payment_date, Time.strptime(date, SUPER_WICKED_PAYPAL_DATE_FORMAT))
    end

    def verification_url
      "#{payment_method.server_url}?cmd=_notify-validate&#{query_string}"
    end
  end
end

# here's a sample PayPal IPN as received on the staging server:
# {
#   "mc_gross"=>"100.00",
#   "protection_eligibility"=>"Eligible",
#   "address_status"=>"unconfirmed",
#   "item_number1"=>"",
#   "payer_id"=>"THR3A6M8M9V6E",
#   "tax"=>"0.00",
#   "address_street"=>"ESpachstr. 1",
#   "payment_date"=>"05:46:49 Oct 16, 2011 PDT",
#   "payment_status"=>"Completed",
#   "charset"=>"windows-1252",
#   "address_zip"=>"79111",
#   "mc_shipping"=>"0.00",
#   "mc_handling"=>"0.00",
#   "first_name"=>"Test",
#   "mc_fee"=>"2.25",
#   "address_country_code"=>"DE",
#   "address_name"=>"Test User",
#   "notify_version"=>"3.4",
#   "custom"=>"5",
#   "payer_status"=>"verified",
#   "business"=>"clemen_1309893207_biz@railway.at",
#   "address_country"=>"Germany",
#   "num_cart_items"=>"1",
#   "mc_handling1"=>"0.00",
#   "address_city"=>"Freiburg",
#   "verify_sign"=>"An5ns1Kso7MWUdW4ErQKJJJ4qi4-ADRmlrj1ecxwIDWnfxx0sjTUHhni",
#   "payer_email"=>"clemen_1309893623_pre@railway.at",
#   "mc_shipping1"=>"0.00",
#   "txn_id"=>"5WM7929182423890V",
#   "payment_type"=>"instant",
#   "last_name"=>"User",
#   "address_state"=>"Empty",
#   "item_name1"=>"OMG Awesome Ticket Standard",
#   "receiver_email"=>"clemen_1309893207_biz@railway.at",
#   "payment_fee"=>"",
#   "quantity1"=>"2",
#   "receiver_id"=>"52Z2YZ3HJLVDN",
#   "txn_type"=>"cart",
#   "mc_gross_1"=>"100.00",
#   "mc_currency"=>"EUR",
#   "residence_country"=>"DE",
#   "test_ipn"=>"1",
#   "transaction_subject"=>"5",
#   "payment_gross"=>"",
#   "ipn_track_id"=>"m0pScf7ueIwyIJ8JT8kxMg",
#   "purchase_id"=>"hdr8knqmvmvd2nobzweog"
# }
