Spree::LineItem.class_eval do
  def full_product_info_for_paypal
    "#{variant.product.name} (#{variant.options_text})"
  end
end
