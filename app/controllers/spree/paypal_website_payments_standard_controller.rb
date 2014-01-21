module Spree
  # TODO can I use CheckoutController as a base?
  class PaypalWebsitePaymentsStandardController < StoreController
    protect_from_forgery :except => :notify

    before_filter :set_payment, :set_order, :set_payment_method

    def pay
      # we need a pending payment if one doesn't exit already
      payment = @order.payments.with_state('checkout').where(:payment_method_id => @payment_method.id).first_or_create(:amount => @order.total)

      paypal_cart = Spree::PaypalCart.new(payment,
        :return        => confirm_paypal_website_payments_standard_url(:payment_id => payment),
        :cancel_return => cancel_paypal_website_payments_standard_url(:payment_id => payment),
        :notify_url    => notify_paypal_website_payments_standard_url(:payment_id => payment),
      )

      redirect_to paypal_cart.redirect_url
    end

    def confirm
      # find payment and determine its validity at the same time
      payment = @order.payments.valid.find_by_id(params[:payment_id])

      if payment.present?
        unless @order.state == 'complete'
          # really? - at least that's similar how it's done with the spree_paypal_express extension (https://github.com/spree/spree_paypal_express/blob/1-3-stable/app/controllers/spree/checkout_controller_decorator.rb#L110-L111)
          @order.state = 'complete'
          # manually finalize it because that's what happens after the transition to complete in the state machine
          @order.finalize!
        end

        flash[:commerce_tracking] = "nothing special"
        redirect_to completion_route, :notice => t(:order_processed_successfully)
      else
        render :text => 'PayPal Error. TODO'
      end
    end

    def notify
      PaypalWebsitePaymentsStandardNotification.process(request)
      head(:ok)
    end

    def cancel
      redirect_to edit_order_path(@order), :alert => t(:payment_has_been_cancelled)
    end

  private

    def completion_route
      order_path(@order)
    end

    def set_payment
      @payment = Payment.find(params[:payment_id]) if params[:payment_id].present?
    end

    def set_order
      @order = @payment.try(:order) || Order.find_by_number!(params[:order_id])
    end

    def set_payment_method
      @payment_method = @payment.try(:payment_method) || PaymentMethod.find(params[:payment_method_id])
    end

  end
end
