module Spree
  class BillingIntegration::PaypalWebsitePaymentsStandard < PaymentMethod
    preference :business, :string
    preference :localization, :string
    preference :login, :string
    preference :password, :string
    preference :signature, :string
    preference :server, :string, default: 'sandbox'

    attr_accessible :preferred_business, :preferred_localization
    attr_accessible :preferred_login, :preferred_password, :preferred_signature, :preferred_server

    def server_url
      "https://www#{'.sandbox' if preferred_server == 'sandbox'}.paypal.com/cgi-bin/webscr"
    end

    def method_type
      'paypal'
    end
  end
end
