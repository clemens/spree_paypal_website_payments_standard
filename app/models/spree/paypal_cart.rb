# encoding: utf-8

module Spree
  class PaypalCart
    def initialize(payment, params = {})
      @payment = payment
      @order = payment.order
      @payment_method = payment.payment_method
      @params = params

      apply_params
    end

    def redirect_url
      URI.parse(@payment_method.server_url).tap do |uri|
        uri.query = @params.to_query
      end.to_s
    end

  private

    def apply_params
      add_order_params
      add_order_line_params

      apply_addresses
      apply_shipping_costs
      apply_promo
    end

    def add_order_params
      # see https://developer.paypal.com/docs/classic/paypal-payments-standard/integration-guide/Appx_websitestandard_htmlvariables/
      @params.merge!(
        :business         => @payment_method.preferred_business,
        :cmd              => '_cart',
        :paymentaction    => @payment_method.auto_capture? ? 'sale' : 'authorization', # authorization, sale or order
        :upload           => '1',
        :invoice          => @payment.identifier,
        :currency_code    => @order.currency,
        :rm               => '0', # 0 = GET with variables, 1 = GET without variables, 2 = POST with variables
        :no_shipping      => '1', # 0 = shipping address optional, 1 = shipping address disabled, 2 = shipping address required
        :no_note          => '1', # hide notes box
        :lc               => localization,
        :charset          => 'UTF-8',
        :address_override => '1', # don't allow user to enter another address
        :tax_cart         => @order.tax_total,
      )
    end

    def localization
      @payment_method.preferred_localization # override this as needed for multilingual apps
    end

    def apply_addresses
      # TODO
      # @params.merge!(
      #   :address1   => @order.bill_address.address1,
      #   :address2   => @order.bill_address.address2,
      #   :zip        => @order.bill_address.zipcode,
      #   :city       => @order.bill_address.city,
      #   :country    => @order.bill_address.country.iso,
      #   :first_name => @order.bill_address.firstname,
      #   :last_name  => @order.bill_address.lastname,
      #   :email      => @order.email,
      # )
      # @params.merge!(:state => @order.bill_address.state.try(:abbr)) if @order.bill_address.state.present?

      # if @order.bill_address.phone.present?
      #   @params.merge!(:night_phone_a => ..., :night_phone_b => ...)
      # end
    end

    def apply_shipping_costs
      @params.merge!(:shipping_1 => @order.ship_total)
    end

    def apply_promo
      @params.merge!(:discount_amount_cart => @order.promo_total.abs) if @order.promo_total < 0 # promo is negative!
    end

    def add_order_line_params
      # TODO tax_i/tax_rate_i?, discount_amount_i/discount_rate_i?
      @order.line_items.each_with_index do |line, i|
        idx = i + 1

        @params.merge!(
          "item_number_#{idx}" => line.variant.sku,
          "quantity_#{idx}"    => line.quantity,
          "item_name_#{idx}"   => line.full_product_info_for_paypal,
          "amount_#{idx}"      => line.price,
          # "tax_rate_#{idx}"  => line.vat_rate * 100,
        )
      end
    end

  end
end
