class ChangeUniqueIndexOnSpreeWebsitePaymentsStandardTransactions < ActiveRecord::Migration
  def up
    add_index :spree_website_payments_standard_transactions, [:transaction_id, :payment_status], :name => 'unique_index_paypal_standard_notifications'
    remove_index :spree_website_payments_standard_transactions, 'unique_idx_paypal_standard_notifications_transaction_id'
  end
end

