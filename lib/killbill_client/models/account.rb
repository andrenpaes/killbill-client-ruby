module KillBillClient
  module Model
    class Account < AccountAttributes

      KILLBILL_API_ACCOUNTS_PREFIX = "#{KILLBILL_API_PREFIX}/accounts"

      include KillBillClient::Model::TagHelper
      include KillBillClient::Model::CustomFieldHelper

      has_custom_fields KILLBILL_API_ACCOUNTS_PREFIX, :account_id
      has_tags KILLBILL_API_ACCOUNTS_PREFIX, :account_id

      has_many :audit_logs, KillBillClient::Model::AuditLog

      class << self
        def find_in_batches(offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{Resource::KILLBILL_API_PAGINATION_PREFIX}",
              {
                  :offset                   => offset,
                  :limit                    => limit,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_id(account_id, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
              {
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_by_external_key(external_key, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}",
              {
                  :externalKey              => external_key,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end

        def find_in_batches_by_search_key(search_key, offset = 0, limit = 100, with_balance = false, with_balance_and_cba = false, options = {})
          get "#{KILLBILL_API_ACCOUNTS_PREFIX}/search/#{search_key}",
              {
                  :offset                   => offset,
                  :limit                    => limit,
                  :accountWithBalance       => with_balance,
                  :accountWithBalanceAndCBA => with_balance_and_cba
              },
              options
        end
      end

      def create(user = nil, reason = nil, comment = nil, options = {})
        created_account = self.class.post KILLBILL_API_ACCOUNTS_PREFIX,
                                          to_json,
                                          {},
                                          {
                                              :user    => user,
                                              :reason  => reason,
                                              :comment => comment,
                                          }.merge(options)
        created_account.refresh(options)
      end

      def update(treat_null_as_reset = false, user = nil, reason = nil, comment = nil, options = {})

        params = {}
        params[:treatNullAsReset] = treat_null_as_reset

        updated_account = self.class.put "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}",
                                         to_json,
                                         params,
                                         {
                                             :user    => user,
                                             :reason  => reason,
                                             :comment => comment,
                                         }.merge(options)
        updated_account.refresh(options)
      end


      def transfer_child_credit(user = nil, reason = nil, comment = nil, options = {})
        self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/transferCredit",
                                         {},
                                         {},
                                         {
                                             :user    => user,
                                             :reason  => reason,
                                             :comment => comment,
                                         }.merge(options)
      end


      def bundles(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/bundles",
                       {},
                       options,
                       Bundle
      end

      def invoices(with_items=false, options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/invoices",
                       {
                           :withItems => with_items
                       },
                       options,
                       Invoice
      end

      def payments(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/payments",
                       {},
                       options,
                       Payment
      end

      def overdue(options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/overdue",
                       {},
                       options,
                       OverdueStateAttributes
      end

      def auto_pay_off?(options = {})
        control_tag?(AUTO_PAY_OFF_ID, options)
      end

      def set_auto_pay_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(AUTO_PAY_OFF_ID, user, reason, comment, options)
      end

      def remove_auto_pay_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(AUTO_PAY_OFF_ID, user, reason, comment, options)
      end

      def auto_invoicing_off?(options = {})
        control_tag?(AUTO_INVOICING_OFF_ID, options)
      end

      def set_auto_invoicing_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(AUTO_INVOICING_OFF_ID, user, reason, comment, options)
      end

      def remove_auto_invoicing_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(AUTO_INVOICING_OFF_ID, user, reason, comment, options)
      end

      def overdue_enforcement_off?(options = {})
        control_tag?(OVERDUE_ENFORCEMENT_OFF_ID, options)
      end

      def set_overdue_enforcement_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(OVERDUE_ENFORCEMENT_OFF_ID, user, reason, comment, options)
      end

      def remove_overdue_enforcement_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(OVERDUE_ENFORCEMENT_OFF_ID, user, reason, comment, options)
      end

      def written_off?(options = {})
        control_tag?(WRITTEN_OFF_ID, options)
      end

      def set_written_off(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(WRITTEN_OFF_ID, user, reason, comment, options)
      end

      def remove_written_off(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(WRITTEN_OFF_ID, user, reason, comment, options)
      end

      def manual_pay?(options = {})
        control_tag?(MANUAL_PAY_ID, options)
      end

      def set_manual_pay(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(MANUAL_PAY_ID, user, reason, comment, options)
      end

      def remove_manual_pay(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(MANUAL_PAY_ID, user, reason, comment, options)
      end

      def test?(options = {})
        control_tag?(TEST_ID, options)
      end

      def set_test(user = nil, reason = nil, comment = nil, options = {})
        add_tag_from_definition_id(TEST_ID, user, reason, comment, options)
      end

      def remove_test(user = nil, reason = nil, comment = nil, options = {})
        remove_tag_from_definition_id(TEST_ID, user, reason, comment, options)
      end

      def add_email(email, user = nil, reason = nil, comment = nil, options = {})
        self.class.post "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails",
                        {
                            # TODO Required ATM
                            :accountId => account_id,
                            :email     => email
                        }.to_json,
                        {},
                        {
                            :user    => user,
                            :reason  => reason,
                            :comment => comment,
                        }.merge(options)
      end

      def remove_email(email, user = nil, reason = nil, comment = nil, options = {})
        self.class.delete "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails/#{email}",
                          {},
                          {},
                          {
                              :user    => user,
                              :reason  => reason,
                              :comment => comment,
                          }.merge(options)
      end

      def emails(audit = 'NONE', options = {})
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emails",
                       {
                           :audit => audit
                       },
                       options,
                       AccountEmailAttributes
      end

      def update_email_notifications(user = nil, reason = nil, comment = nil, options = {})
        self.class.put "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/emailNotifications",
                       to_json,
                       {},
                       {
                           :user => user,
                           :reason => reason,
                           :comment => comment,
                       }.merge(options)
      end

      def all_tags(object_type, included_deleted, audit = 'NONE', options = {})

        params = {}
        params[:objectType] = object_type if object_type
        params[:includedDeleted] = included_deleted if included_deleted
        params[:audit] = audit
        self.class.get "#{KILLBILL_API_ACCOUNTS_PREFIX}/#{account_id}/allTags",
                       params,
                       options,
                       Tag
      end
    end
  end
end
