# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paypal_website_payments_standard'
  s.version     = '1.3.0'
  s.summary     = 'PayPal Website Payments Standard checkout for use with Spree.'
  s.description = 'PayPal Website Payments Standard checkout for use with Spree'

  s.required_ruby_version = '>= 1.8.7'
  s.author      = 'Clemens Kofler'
  s.email       = 'clemens@railway.at'
  s.homepage    = 'http://railway.at'

  s.files        = Dir['README', 'LICENSE', 'app/**/*', 'config/**/*', 'lib/**/*', 'db/**/*', 'test/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 1.3.0'
end
