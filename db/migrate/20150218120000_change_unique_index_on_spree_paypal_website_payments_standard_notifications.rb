class ChangeUniqueIndexOnSpreePaypalWebsitePaymentsStandardNotifications < ActiveRecord::Migration
  def up
    add_index :spree_paypal_website_payments_standard_notifications, [:transaction_id, :payment_status], :name => 'unique_index_paypal_standard_notifications'
    remove_index :spree_paypal_website_payments_standard_notifications, :name => 'unique_idx_paypal_standard_notifications_order_id'
  end
end

