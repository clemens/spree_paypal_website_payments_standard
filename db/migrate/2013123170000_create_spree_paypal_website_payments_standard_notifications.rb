class CreateSpreePaypalWebsitePaymentsStandardNotifications < ActiveRecord::Migration
  def change
    create_table :spree_paypal_website_payments_standard_notifications do |t|
      t.belongs_to :order

      t.string :transaction_id
      t.string :payment_status

      t.text :query_string
      t.text :params

      t.timestamps
    end

    add_index :spree_paypal_website_payments_standard_notifications, :order_id, :name => 'idx_paypal_standard_notifications_order_id'
    add_index :spree_paypal_website_payments_standard_notifications, :transaction_id, :unique => true, :name => 'unique_idx_paypal_standard_notifications_order_id'
  end
end
