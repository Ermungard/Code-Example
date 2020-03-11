# frozen_string_literal: true

namespace :update_data do
  desc 'Отправляем правила из организаций в stratum'
  task send_rules_to_stratum: [:environment] do
    def stratum_params(state_value, dpc_value, region_uuid, type_value)
      type_vdc = case type_value
                 when 'vdc'
                   'openstack'
                 when 'xvdc'
                   'vmware'
                 when 'aicloud'
                   'aicloud_jupyter'
                 when 's3'
                   'ecs_appliance_s3'
                 end

      {
        state: state_value,
        dpc: dpc_value,
        conditions: {
          ir_type: type_vdc,
          domain_id: region_uuid,
        },
      }
    end

    Region.find_each do |regions|
      begin
        regions['allowed_vdcs'].each do |type_value, rules_value|
          state_skolkovo = rules_value.include?('skolkovo') ? 'open' : 'close'
          state_datapro = rules_value.include?('datapro') ? 'open' : 'close'
          main_params = {
            rules: [
              stratum_params(state_skolkovo, 'skolkovo', regions['uuid'], type_value),
              stratum_params(state_datapro, 'datapro', regions['uuid'], type_value),
            ],
          }
          result = StratumService.new(:rules, main_params).call
          puts "Правила области #{regions['uuid']} успешно обновлены #{result}"
        end
      rescue StandardError => e
        Rails.logger.error 'Обновить правила области не удалось'
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end