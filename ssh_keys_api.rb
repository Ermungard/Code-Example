# frozen_string_literal: true

class RestAPI
  module V1
    class SshKeysAPI < Grape::API
      version 'v1', using: :path
      format :json

      resource :ssh_keys do
        desc 'Список ssh-ключей пользователя',
             success: RestAPI::Entities::SshKey,
             is_array: true
        get do
          present current_user.ssh_keys, with: RestAPI::Entities::SshKey
        end

        desc 'Устанавливает флаг по умолчанию для ключа',
             success: { status: 'set by default' }
        params do
          requires :uuid, types: String, desc: 'Уникальный идентификатор ключа', documentation: { param_type: 'body' }
        end
        patch do
          keys = current_user.ssh_keys.find_by(uuid: params[:uuid])
          error!({ error: 'key not found' }, 404) if keys.blank?
          error!({ error: 'SSH public key is incorrect' }, 422) unless keys.valid?
          current_user.ssh_keys.update_all(default: false)
          present keys&.tap { |ssh_key| ssh_key.update_attributes(default: true) }, with: RestAPI::Entities::SshKey
        end

        desc 'Добавляет новый ключ для пользователя, параметры: public_ssh_name, public_ssh, def as default',
             success: { status: 'key added' },
             failure: [{ code: 422, message: 'Ошибка при создании SSH-ключа', model: RestAPI::Entities::ApiError }]
        params do
          requires :ssh_key, type: Hash do
            requires :public_ssh_name, types: String, desc: 'Название SSH ключа', documentation: { param_type: 'body' }
            requires :public_ssh, types: String, desc: 'SSH ключ', documentation: { param_type: 'body' }
            requires :def, type: Virtus::Attribute::Boolean, default: false, documentation: { param_type: 'body' }
          end
        end
        post do
          parameters = params[:ssh_key]
          error!({ error: 'Параметры public_ssh_name и public_ssh не могут быть пустыми' }, 422) if parameters[:public_ssh].blank? || parameters[:public_ssh_name].blank?
          is_first = current_user.ssh_keys.blank?
          ssh_key = SshKey.new(user_id: current_user.id, public_ssh_name: parameters[:public_ssh_name], public_ssh: parameters[:public_ssh], default: is_first || parameters[:def])
          error!({ error: 'SSH public key is incorrect' }, 422) unless ssh_key.valid?
          current_user.ssh_keys.update_all(default: false) if !is_first && parameters[:def]
          ssh_key.save
          present ssh_key, with: RestAPI::Entities::SshKey
        end

        desc 'Удаление ключа по uuid',
             success: { status: 'Is deleted' }
        params do
          requires :uuid, types: String, desc: 'Уникальный идентификатор ключа'
        end
        route_param :uuid do
          delete do
            ssh_key = SshKey.find_by(uuid: params[:uuid])
            error!({ error: 'not_found' }, 404) if ssh_key.blank?
            error!({ error: 'Access Denied' }, 403) if ssh_key.user != current_user
            ssh_key.destroy
            current_user.ssh_keys.first&.update_attributes(default: true) if ssh_key.default

            status :no_content
          end
        end
      end
    end
  end
end
