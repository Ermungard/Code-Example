# frozen_string_literal: true

class RestAPI
  module Entities
    class SshKey < Grape::Entity
      root :ssh_keys, :ssh_key

      expose :uuid, documentation: { type: 'uuid', desc: 'Уникальный идентификатор UUID', required: true }
      expose :public_ssh_name, documentation: { type: 'string', desc: 'Название', required: true }
      expose :public_ssh, documentation: { type: 'string', desc: 'SSH-ключ', required: true }
      expose :default, documentation: { type: 'boolean', desc: 'Основной', required: true }
    end
  end
end
