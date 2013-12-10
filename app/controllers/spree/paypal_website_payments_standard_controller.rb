module Spree
  # TODO can I use CheckoutController as a base?
  class PaypalWebsitePaymentsStandardController < StoreController
    protect_from_forgery :except => :notify

    before_filter :set_order, :set_payment_method

    def pay
      paypal_cart = Spree::PaypalCart.new(@order, @payment_method,
        :return        => confirm_paypal_website_payments_standard_url(:order_id => @order, :payment_method_id => @payment_method),
        :cancel_return => cancel_paypal_website_payments_standard_url(:order_id => @order, :payment_method_id => @payment_method),
        :notify_url    => notify_paypal_website_payments_standard_url(:order_id => @order, :payment_method_id => @payment_method),
      )

      redirect_to paypal_cart.redirect_url
    end

    def confirm
      # we need a pending transaction if one doesn't exit already
      payment = @order.payments.pending.where(:payment_method_id => @payment_method.id).first_or_initialize(:amount => @order.total)
      if payment.source.blank?
        transaction = PaypalWebsitePaymentsStandardTransaction.create!
        payment.update_attribute(:source, transaction)
        payment.pend!
        @order.reload
      end

      # really? - at least that's how it's done with the spree_paypal_express extension (https://github.com/spree/spree_paypal_express/blob/1-3-stable/app/controllers/spree/checkout_controller_decorator.rb#L110-L111)
      @order.state = 'complete'
      @order.save

      redirect_to completion_route, :notice => t(:order_processed_successfully)
    end

    def notify
      PaypalWebsitePaymentsStandardTransaction.process(request)
      head(:ok)
    end

    def cancel
      redirect_to edit_order_path(@order), :alert => t(:payment_has_been_cancelled)
    end

  private

    def completion_route
      spree_completed_order_path(@order)
    end

    def set_order
      @order = Order.find_by_number!(params[:order_id])
    end

    def set_payment_method
      @payment_method = PaymentMethod.find(params[:payment_method_id])
    end

  end
end
