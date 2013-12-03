class CreateSpreePaypalWebsitePaymentsStandardTransactions < ActiveRecord::Migration
  def change
    create_table :spree_paypal_website_payments_standard_transactions do |t|
      t.belongs_to :order

      t.string :business
      t.string :receiver_email
      t.string :transaction_type
      t.string :transaction_id
      t.string :verification_signature
      t.string :status
      t.string :payment_status

      t.decimal  :amount, :precision => 12, :scale => 2
      t.datetime :payment_date

      t.string :query_string, :limit => 2048
      t.text   :params

      t.timestamps
    end

    add_index :spree_paypal_website_payments_standard_transactions, :order_id, :name => 'idx_paypal_standard_transactions_order_id'
  end
end
