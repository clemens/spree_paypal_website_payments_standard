Spree::Core::Engine.routes.prepend do
  get '/paypal_standard',         :to => 'paypal_website_payments_standard#pay',     :as => :pay_paypal_website_payments_standard
  get '/paypal_standard/confirm', :to => 'paypal_website_payments_standard#confirm', :as => :confirm_paypal_website_payments_standard
  get '/paypal_standard/notify',  :to => 'paypal_website_payments_standard#notify',  :as => :notify_paypal_website_payments_standard
  get '/paypal_standard/cancel',  :to => 'paypal_website_payments_standard#cancel',  :as => :cancel_paypal_website_payments_standard
end
