module Spree
  # TODO can I use CheckoutController as a base?
  class PaypalWebsitePaymentsStandardController < StoreController
    protect_from_forgery :except => :notify

    def pay
      # we need a pending payment if one doesn't exit already
      payment = order.payments.with_state('checkout').where(:payment_method_id => payment_method.id).first_or_create(:amount => order.total)

      paypal_cart = Spree::PaypalCart.new(payment,
        :return        => confirm_paypal_website_payments_standard_url(:payment_id => payment, :token => order.token),
        :cancel_return => cancel_paypal_website_payments_standard_url(:payment_id => payment, :token => order.token),
        :notify_url    => notify_paypal_website_payments_standard_url(:payment_id => payment, :token => order.token),
      )

      redirect_to paypal_cart.redirect_url
    end

    def confirm
      # find payment and determine its validity at the same time
      payment = order.payments.valid.find_by_id(params[:payment_id])

      if payment.present?
        PaypalWebsitePaymentsStandardNotification.finalize_order(order)

        flash[:commerce_tracking] = 'nothing special'
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
      redirect_to edit_order_path(order), :alert => t(:payment_has_been_cancelled)
    end

  private

    def completion_route
      order_path(order)
    end

    def payment
      @payment ||= Payment.find(params[:payment_id]) if params[:payment_id].present?
    end

    def order
      @order ||= (payment.try(:order) || Order.find_by_number!(params[:order_id])).tap do |order|
        session[:access_token] ||= params[:token]
        authorize! :edit, order, session[:access_token]
      end
    end

    def payment_method
      @payment_method ||= payment.try(:payment_method) || PaymentMethod.find(params[:payment_method_id])
    end

  end
end
