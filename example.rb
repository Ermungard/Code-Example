	def moving_clusters
    orchestrator_adapter.send_signal(current_project['id'], 'moving_clusters', new_cluster_attrs, user&.uuid, requester_org&.id)
  end

  def new_cluster_attrs
    {
      parent_order_id: new_project['id'],
      customer_id: new_project['customer_id'],
      cluster_uuids: all_cluster_uuid,
      tariff_plan: @regional_tariff_plan,
    }
	end
	
	def all_cluster_uuid
    @all_cluster_uuid ||= all_vms.map { |vm| vm['data']['uuid'] if vm['data']['type'] == 'cluster' }.compact
  end

  def others_uuid
    @others_uuid ||= all_vms.map { |vm| vm['data']['uuid'] if vm['data']['type'] != 'cluster' }.compact
  end
