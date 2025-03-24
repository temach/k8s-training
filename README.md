# About /metrics api kube api server

Kubernetes has resource apis and non-resource-urls, this is visible in e.g:
```
$ k describe role -n kube-system kubeadm:nodes-kubeadm-config
Name:         kubeadm:nodes-kubeadm-config
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources   Non-Resource URLs  Resource Names    Verbs
  ---------   -----------------  --------------    -----
  configmaps  []                 [kubeadm-config]  [get]

```


Only clusterroles can acces Non-Resource URLs, here are pre-installed clusterroles and their urls:
```
$ k describe clusterroles 
...

Name:         system:discovery
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
             [/api/*]           []              [get]
             [/api]             []              [get]
             [/apis/*]          []              [get]
             [/apis]            []              [get]
             [/healthz]         []              [get]
             [/livez]           []              [get]
             [/openapi/*]       []              [get]
             [/openapi]         []              [get]
             [/readyz]          []              [get]
             [/version/]        []              [get]
             [/version]         []              [get]

Name:         system:service-account-issuer-discovery
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources  Non-Resource URLs                     Resource Names  Verbs
  ---------  -----------------                     --------------  -----
             [/.well-known/openid-configuration/]  []              [get]
             [/.well-known/openid-configuration]   []              [get]
             [/openid/v1/jwks/]                    []              [get]
             [/openid/v1/jwks]                     []              [get]

Name:         system:monitoring
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
             [/healthz/*]       []              [get]
             [/healthz]         []              [get]
             [/livez/*]         []              [get]
             [/livez]           []              [get]
             [/metrics/slis]    []              [get]
             [/metrics]         []              [get]
             [/readyz/*]        []              [get]
             [/readyz]          []              [get]
```

Check /metrics raw api call works for admin:
```
$ k get --raw /metrics
# HELP aggregator_discovery_aggregation_count_total [ALPHA] Counter of number of times discovery was aggregated
# TYPE aggregator_discovery_aggregation_count_total counter
aggregator_discovery_aggregation_count_total 274
# HELP aggregator_unavailable_apiservice [ALPHA] Gauge of APIServices which are marked as unavailable broken down by APIService name.
# TYPE aggregator_unavailable_apiservice gauge
aggregator_unavailable_apiservice{name="v1."} 0
aggregator_unavailable_apiservice{name="v1.admissionregistration.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apiextensions.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apps"} 0
aggregator_unavailable_apiservice{name="v1.authentication.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.authorization.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.autoscaling"} 0
aggregator_unavailable_apiservice{name="v1.batch"} 0
aggregator_unavailable_apiservice{name="v1.certificates.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.coordination.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.discovery.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.events.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.flowcontrol.apiserver.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.networking.istio.io"} 0
aggregator_unavailable_apiservice{name="v1.networking.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.node.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.policy"} 0
aggregator_unavailable_apiservice{name="v1.rbac.authorization.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.scheduling.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.security.istio.io"} 0
aggregator_unavailable_apiservice{name="v1.storage.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.telemetry.istio.io"} 0
aggregator_unavailable_apiservice{name="v1alpha1.extensions.istio.io"} 0
aggregator_unavailable_apiservice{name="v1alpha1.kiali.io"} 0
aggregator_unavailable_apiservice{name="v1alpha1.telemetry.istio.io"} 0
aggregator_unavailable_apiservice{name="v1alpha3.networking.istio.io"} 0
aggregator_unavailable_apiservice{name="v1beta1.metrics.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1beta1.networking.istio.io"} 0
aggregator_unavailable_apiservice{name="v1beta1.security.istio.io"} 0
aggregator_unavailable_apiservice{name="v2.autoscaling"} 0
...

$ k get --raw /metrics | awk -F{ '/^[^#]/ {print $1}' | sort | uniq -c
      1 aggregator_discovery_aggregation_count_total 69
     30 aggregator_unavailable_apiservice
      1 aggregator_unavailable_apiservice_total
     11 apiextensions_apiserver_validation_ratcheting_seconds_bucket
      1 apiextensions_apiserver_validation_ratcheting_seconds_count 0
      1 apiextensions_apiserver_validation_ratcheting_seconds_sum 0
     14 apiextensions_openapi_v2_regeneration_count
     30 apiextensions_openapi_v3_regeneration_count
    371 apiserver_admission_controller_admission_duration_seconds_bucket
     53 apiserver_admission_controller_admission_duration_seconds_count
     53 apiserver_admission_controller_admission_duration_seconds_sum
     56 apiserver_admission_step_admission_duration_seconds_bucket
      8 apiserver_admission_step_admission_duration_seconds_count
      8 apiserver_admission_step_admission_duration_seconds_sum
     24 apiserver_admission_step_admission_duration_seconds_summary
      8 apiserver_admission_step_admission_duration_seconds_summary_count
      8 apiserver_admission_step_admission_duration_seconds_summary_sum
      1 apiserver_audit_event_total 0
      1 apiserver_audit_requests_rejected_total 0
      2 apiserver_authorization_decisions_total
     39 apiserver_cache_list_fetched_objects_total
     38 apiserver_cache_list_returned_objects_total
     39 apiserver_cache_list_total
     12 apiserver_cel_compilation_duration_seconds_bucket
      1 apiserver_cel_compilation_duration_seconds_count 2975
      1 apiserver_cel_compilation_duration_seconds_sum 0.5799227729999976
     12 apiserver_cel_evaluation_duration_seconds_bucket
      1 apiserver_cel_evaluation_duration_seconds_count 0
      1 apiserver_cel_evaluation_duration_seconds_sum 0
     15 apiserver_client_certificate_expiration_seconds_bucket
      1 apiserver_client_certificate_expiration_seconds_count 8065
      1 apiserver_client_certificate_expiration_seconds_sum 2.154243771845216e+11
      1 apiserver_clusterip_repair_reconcile_errors_total 0
      2 apiserver_current_inflight_requests
      2 apiserver_current_inqueue_requests
      1 apiserver_envelope_encryption_dek_cache_fill_percent 0
     13 apiserver_flowcontrol_current_executing_requests
     13 apiserver_flowcontrol_current_executing_seats
     10 apiserver_flowcontrol_current_inqueue_requests
     10 apiserver_flowcontrol_current_inqueue_seats
      8 apiserver_flowcontrol_current_limit_seats
      8 apiserver_flowcontrol_current_r
      8 apiserver_flowcontrol_demand_seats_average
    104 apiserver_flowcontrol_demand_seats_bucket
      8 apiserver_flowcontrol_demand_seats_count
      8 apiserver_flowcontrol_demand_seats_high_watermark
      8 apiserver_flowcontrol_demand_seats_smoothed
      8 apiserver_flowcontrol_demand_seats_stdev
      8 apiserver_flowcontrol_demand_seats_sum
     13 apiserver_flowcontrol_dispatched_requests_total
      6 apiserver_flowcontrol_dispatch_r
      6 apiserver_flowcontrol_latest_s
      8 apiserver_flowcontrol_lower_limit_seats
     12 apiserver_flowcontrol_next_discounted_s_bounds
     12 apiserver_flowcontrol_next_s_bounds
      8 apiserver_flowcontrol_nominal_limit_seats
    176 apiserver_flowcontrol_priority_level_request_utilization_bucket
     16 apiserver_flowcontrol_priority_level_request_utilization_count
     16 apiserver_flowcontrol_priority_level_request_utilization_sum
    112 apiserver_flowcontrol_priority_level_seat_utilization_bucket
      8 apiserver_flowcontrol_priority_level_seat_utilization_count
      8 apiserver_flowcontrol_priority_level_seat_utilization_sum
     64 apiserver_flowcontrol_read_vs_write_current_requests_bucket
      4 apiserver_flowcontrol_read_vs_write_current_requests_count
      4 apiserver_flowcontrol_read_vs_write_current_requests_sum
    308 apiserver_flowcontrol_request_execution_seconds_bucket
     22 apiserver_flowcontrol_request_execution_seconds_count
     22 apiserver_flowcontrol_request_execution_seconds_sum
     90 apiserver_flowcontrol_request_queue_length_after_enqueue_bucket
     10 apiserver_flowcontrol_request_queue_length_after_enqueue_count
     10 apiserver_flowcontrol_request_queue_length_after_enqueue_sum
    154 apiserver_flowcontrol_request_wait_duration_seconds_bucket
     11 apiserver_flowcontrol_request_wait_duration_seconds_count
     11 apiserver_flowcontrol_request_wait_duration_seconds_sum
      1 apiserver_flowcontrol_seat_fair_frac 2.3333333333333335
      8 apiserver_flowcontrol_target_seats
      8 apiserver_flowcontrol_upper_limit_seats
     77 apiserver_flowcontrol_watch_count_samples_bucket
     11 apiserver_flowcontrol_watch_count_samples_count
     11 apiserver_flowcontrol_watch_count_samples_sum
     65 apiserver_flowcontrol_work_estimated_seats_bucket
     13 apiserver_flowcontrol_work_estimated_seats_count
     13 apiserver_flowcontrol_work_estimated_seats_sum
     26 apiserver_init_events_total
      1 apiserver_kube_aggregator_x509_insecure_sha1_total 0
      1 apiserver_kube_aggregator_x509_missing_san_total 0
     70 apiserver_longrunning_requests
      1 apiserver_nodeport_repair_reconcile_errors_total 0
   1376 apiserver_request_body_size_bytes_bucket
     43 apiserver_request_body_size_bytes_count
     43 apiserver_request_body_size_bytes_sum
   4392 apiserver_request_duration_seconds_bucket
    183 apiserver_request_duration_seconds_count
    183 apiserver_request_duration_seconds_sum
     70 apiserver_request_filter_duration_seconds_bucket
      5 apiserver_request_filter_duration_seconds_count
      5 apiserver_request_filter_duration_seconds_sum
   2596 apiserver_request_sli_duration_seconds_bucket
    118 apiserver_request_sli_duration_seconds_count
    118 apiserver_request_sli_duration_seconds_sum
      1 apiserver_request_terminations_total
     22 apiserver_request_timestamp_comparison_time_bucket
      2 apiserver_request_timestamp_comparison_time_count
      2 apiserver_request_timestamp_comparison_time_sum
    202 apiserver_request_total
    976 apiserver_response_sizes_bucket
    122 apiserver_response_sizes_count
    122 apiserver_response_sizes_sum
     73 apiserver_selfrequest_total
     15 apiserver_storage_data_key_generation_duration_seconds_bucket
      1 apiserver_storage_data_key_generation_duration_seconds_count 0
      1 apiserver_storage_data_key_generation_duration_seconds_sum 0
      1 apiserver_storage_data_key_generation_failures_total 0
      1 apiserver_storage_envelope_transformation_cache_misses_total 0
     15 apiserver_storage_events_received_total
     64 apiserver_storage_list_evaluated_objects_total
     64 apiserver_storage_list_fetched_objects_total
     64 apiserver_storage_list_returned_objects_total
     64 apiserver_storage_list_total
     63 apiserver_storage_objects
      1 apiserver_storage_size_bytes
      1 apiserver_tls_handshake_errors_total 44
     11 apiserver_watch_cache_consistent_read_total
     62 apiserver_watch_cache_events_dispatched_total
     15 apiserver_watch_cache_events_received_total
     62 apiserver_watch_cache_initializations_total
    868 apiserver_watch_cache_read_wait_seconds_bucket
     62 apiserver_watch_cache_read_wait_seconds_count
     62 apiserver_watch_cache_read_wait_seconds_sum
     62 apiserver_watch_cache_resource_version
    558 apiserver_watch_events_sizes_bucket
     62 apiserver_watch_events_sizes_count
     62 apiserver_watch_events_sizes_sum
     62 apiserver_watch_events_total
   1116 apiserver_watch_list_duration_seconds_bucket
     62 apiserver_watch_list_duration_seconds_count
     62 apiserver_watch_list_duration_seconds_sum
      1 apiserver_webhooks_x509_insecure_sha1_total 0
      1 apiserver_webhooks_x509_missing_san_total 0
      1 authenticated_user_requests
      1 authentication_attempts
     16 authentication_duration_seconds_bucket
      1 authentication_duration_seconds_count
      1 authentication_duration_seconds_sum
      2 authentication_token_cache_active_fetch_count
      1 authentication_token_cache_fetch_total
     24 authentication_token_cache_request_duration_seconds_bucket
      2 authentication_token_cache_request_duration_seconds_count
      2 authentication_token_cache_request_duration_seconds_sum
      2 authentication_token_cache_request_total
      2 authorization_attempts_total
     32 authorization_duration_seconds_bucket
      2 authorization_duration_seconds_count
      2 authorization_duration_seconds_sum
      1 cardinality_enforcement_unexpected_categorizations_total 0
      1 disabled_metrics_total 0
     61 etcd_bookmark_counts
      8 etcd_lease_object_counts_bucket
      1 etcd_lease_object_counts_count 432
      1 etcd_lease_object_counts_sum 1276
   5616 etcd_request_duration_seconds_bucket
    234 etcd_request_duration_seconds_count
    234 etcd_request_duration_seconds_sum
    234 etcd_requests_total
     44 field_validation_request_duration_seconds_bucket
      2 field_validation_request_duration_seconds_count
      2 field_validation_request_duration_seconds_sum
      1 go_cgo_go_to_c_calls_calls_total 0
      1 go_cpu_classes_gc_mark_assist_cpu_seconds_total 0.231671694
      1 go_cpu_classes_gc_mark_dedicated_cpu_seconds_total 3.372924229
      1 go_cpu_classes_gc_mark_idle_cpu_seconds_total 5.207456308
      1 go_cpu_classes_gc_pause_cpu_seconds_total 0.15722453
      1 go_cpu_classes_gc_total_cpu_seconds_total 8.969276761
      1 go_cpu_classes_idle_cpu_seconds_total 8338.851998649
      1 go_cpu_classes_scavenge_assist_cpu_seconds_total 6.73e-07
      1 go_cpu_classes_scavenge_background_cpu_seconds_total 0.047762291
      1 go_cpu_classes_scavenge_total_cpu_seconds_total 0.047762964
      1 go_cpu_classes_total_cpu_seconds_total 8476.29163925
      1 go_cpu_classes_user_cpu_seconds_total 128.422600876
      1 go_gc_cycles_automatic_gc_cycles_total 64
      1 go_gc_cycles_forced_gc_cycles_total 0
      1 go_gc_cycles_total_gc_cycles_total 64
      5 go_gc_duration_seconds
      1 go_gc_duration_seconds_count 64
      1 go_gc_duration_seconds_sum 0.149576103
      1 go_gc_gogc_percent 100
      1 go_gc_gomemlimit_bytes 9.223372036854776e+18
     12 go_gc_heap_allocs_by_size_bytes_bucket
      1 go_gc_heap_allocs_by_size_bytes_count 3.9633219e+07
      1 go_gc_heap_allocs_by_size_bytes_sum 4.769794504e+09
      1 go_gc_heap_allocs_bytes_total 4.769794504e+09
      1 go_gc_heap_allocs_objects_total 3.9633219e+07
     12 go_gc_heap_frees_by_size_bytes_bucket
      1 go_gc_heap_frees_by_size_bytes_count 3.8264349e+07
      1 go_gc_heap_frees_by_size_bytes_sum 4.566436776e+09
      1 go_gc_heap_frees_bytes_total 4.566436776e+09
      1 go_gc_heap_frees_objects_total 3.8264349e+07
      1 go_gc_heap_goal_bytes 3.42738912e+08
      1 go_gc_heap_live_bytes 1.68371248e+08
      1 go_gc_heap_objects_objects 1.36887e+06
      1 go_gc_heap_tiny_allocs_objects_total 2.481718e+06
      1 go_gc_limiter_last_enabled_gc_cycle 0
      8 go_gc_pauses_seconds_bucket
      1 go_gc_pauses_seconds_count 128
      1 go_gc_pauses_seconds_sum 0.132726144
      1 go_gc_scan_globals_bytes 544560
      1 go_gc_scan_heap_bytes 1.28238136e+08
      1 go_gc_scan_stack_bytes 5.451856e+06
      1 go_gc_scan_total_bytes 1.34234552e+08
      1 go_gc_stack_starting_size_bytes 4096
      1 go_godebug_non_default_behavior_asynctimerchan_events_total 0
      1 go_godebug_non_default_behavior_execerrdot_events_total 0
      1 go_godebug_non_default_behavior_gocachehash_events_total 0
      1 go_godebug_non_default_behavior_gocachetest_events_total 0
      1 go_godebug_non_default_behavior_gocacheverify_events_total 0
      1 go_godebug_non_default_behavior_gotypesalias_events_total 0
      1 go_godebug_non_default_behavior_http2client_events_total 0
      1 go_godebug_non_default_behavior_http2server_events_total 0
      1 go_godebug_non_default_behavior_httplaxcontentlength_events_total 0
      1 go_godebug_non_default_behavior_httpmuxgo121_events_total 0
      1 go_godebug_non_default_behavior_httpservecontentkeepheaders_events_total 0
      1 go_godebug_non_default_behavior_installgoroot_events_total 0
      1 go_godebug_non_default_behavior_multipartmaxheaders_events_total 0
      1 go_godebug_non_default_behavior_multipartmaxparts_events_total 0
      1 go_godebug_non_default_behavior_multipathtcp_events_total 0
      1 go_godebug_non_default_behavior_netedns0_events_total 0
      1 go_godebug_non_default_behavior_panicnil_events_total 0
      1 go_godebug_non_default_behavior_randautoseed_events_total 0
      1 go_godebug_non_default_behavior_tarinsecurepath_events_total 0
      1 go_godebug_non_default_behavior_tls10server_events_total 0
      1 go_godebug_non_default_behavior_tls3des_events_total 0
      1 go_godebug_non_default_behavior_tlsmaxrsasize_events_total 0
      1 go_godebug_non_default_behavior_tlsrsakex_events_total 0
      1 go_godebug_non_default_behavior_tlsunsafeekm_events_total 0
      1 go_godebug_non_default_behavior_winreadlinkvolume_events_total 0
      1 go_godebug_non_default_behavior_winsymlink_events_total 0
      1 go_godebug_non_default_behavior_x509keypairleaf_events_total 0
      1 go_godebug_non_default_behavior_x509negativeserial_events_total 0
      1 go_godebug_non_default_behavior_x509sha1_events_total 0
      1 go_godebug_non_default_behavior_x509usefallbackroots_events_total 0
      1 go_godebug_non_default_behavior_x509usepolicies_events_total 0
      1 go_godebug_non_default_behavior_zipinsecurepath_events_total 0
      1 go_goroutines 2590
      1 go_info
      1 go_memory_classes_heap_free_bytes 3.0031872e+07
      1 go_memory_classes_heap_objects_bytes 2.03357728e+08
      1 go_memory_classes_heap_released_bytes 2.62144e+06
      1 go_memory_classes_heap_stacks_bytes 2.0578304e+07
      1 go_memory_classes_heap_unused_bytes 6.2144992e+07
      1 go_memory_classes_metadata_mcache_free_bytes 13200
      1 go_memory_classes_metadata_mcache_inuse_bytes 2400
      1 go_memory_classes_metadata_mspan_free_bytes 480320
      1 go_memory_classes_metadata_mspan_inuse_bytes 4.49728e+06
      1 go_memory_classes_metadata_other_bytes 6.368552e+06
      1 go_memory_classes_os_stacks_bytes 0
      1 go_memory_classes_other_bytes 1.335913e+06
      1 go_memory_classes_profiling_buckets_bytes 3.298567e+06
      1 go_memory_classes_total_bytes 3.34730568e+08
      1 go_memstats_alloc_bytes 2.03357728e+08
      1 go_memstats_alloc_bytes_total 4.769794504e+09
      1 go_memstats_buck_hash_sys_bytes 3.298567e+06
      1 go_memstats_frees_total 4.0746067e+07
      1 go_memstats_gc_sys_bytes 6.368552e+06
      1 go_memstats_heap_alloc_bytes 2.03357728e+08
      1 go_memstats_heap_idle_bytes 3.2653312e+07
      1 go_memstats_heap_inuse_bytes 2.6550272e+08
      1 go_memstats_heap_objects 1.36887e+06
      1 go_memstats_heap_released_bytes 2.62144e+06
      1 go_memstats_heap_sys_bytes 2.98156032e+08
      1 go_memstats_last_gc_time_seconds 1.7427548126575298e+09
      1 go_memstats_lookups_total 0
      1 go_memstats_mallocs_total 4.2114937e+07
      1 go_memstats_mcache_inuse_bytes 2400
      1 go_memstats_mcache_sys_bytes 15600
      1 go_memstats_mspan_inuse_bytes 4.49728e+06
      1 go_memstats_mspan_sys_bytes 4.9776e+06
      1 go_memstats_next_gc_bytes 3.42738912e+08
      1 go_memstats_other_sys_bytes 1.335913e+06
      1 go_memstats_stack_inuse_bytes 2.0578304e+07
      1 go_memstats_stack_sys_bytes 2.0578304e+07
      1 go_memstats_sys_bytes 3.34730568e+08
      1 go_sched_gomaxprocs_threads 2
      1 go_sched_goroutines_goroutines 2590
      8 go_sched_latencies_seconds_bucket
      1 go_sched_latencies_seconds_count 565060
      1 go_sched_latencies_seconds_sum 5.381062976
      8 go_sched_pauses_stopping_gc_seconds_bucket
      1 go_sched_pauses_stopping_gc_seconds_count 128
      1 go_sched_pauses_stopping_gc_seconds_sum 0.130974144
      8 go_sched_pauses_stopping_other_seconds_bucket
      1 go_sched_pauses_stopping_other_seconds_count 0
      1 go_sched_pauses_stopping_other_seconds_sum 0
      8 go_sched_pauses_total_gc_seconds_bucket
      1 go_sched_pauses_total_gc_seconds_count 128
      1 go_sched_pauses_total_gc_seconds_sum 0.132726144
      8 go_sched_pauses_total_other_seconds_bucket
      1 go_sched_pauses_total_other_seconds_count 0
      1 go_sched_pauses_total_other_seconds_sum 0
      1 go_sync_mutex_wait_total_seconds_total 0.242055032
      1 go_threads 9
      6 grpc_client_handled_total
      1 grpc_client_msg_received_total
      6 grpc_client_msg_sent_total
      6 grpc_client_started_total
      1 hidden_metrics_total 8
      1 kube_apiserver_clusterip_allocator_allocated_ips
      1 kube_apiserver_clusterip_allocator_allocation_total
      1 kube_apiserver_clusterip_allocator_available_ips
      1 kube_apiserver_nodeport_allocator_allocated_ports 0
      1 kube_apiserver_nodeport_allocator_available_ports 0
      1 kube_apiserver_pod_logs_backend_tls_failure_total 0
      1 kube_apiserver_pod_logs_insecure_backend_total
      1 kubernetes_build_info
    178 kubernetes_feature_enabled
     39 node_authorizer_graph_actions_duration_seconds_bucket
      3 node_authorizer_graph_actions_duration_seconds_count
      3 node_authorizer_graph_actions_duration_seconds_sum
      3 pod_security_evaluations_total
      4 pod_security_exemptions_total
      1 process_cpu_seconds_total 129.43
      1 process_max_fds 1.048576e+06
      1 process_open_fds 129
      1 process_resident_memory_bytes 4.1238528e+08
      1 process_start_time_seconds 1.74275057196e+09
      1 process_virtual_memory_bytes 1.629036544e+09
      1 process_virtual_memory_max_bytes 1.8446744073709552e+19
      3 registered_metrics_total
     12 rest_client_exec_plugin_certificate_rotation_age_bucket
      1 rest_client_exec_plugin_certificate_rotation_age_count 0
      1 rest_client_exec_plugin_certificate_rotation_age_sum 0
      1 rest_client_exec_plugin_ttl_seconds +Inf
     26 rest_client_request_duration_seconds_bucket
      2 rest_client_request_duration_seconds_count
      2 rest_client_request_duration_seconds_sum
     24 rest_client_request_size_bytes_bucket
      2 rest_client_request_size_bytes_count
      2 rest_client_request_size_bytes_sum
      3 rest_client_requests_total
     24 rest_client_response_size_bytes_bucket
      2 rest_client_response_size_bytes_count
      2 rest_client_response_size_bytes_sum
      1 rest_client_transport_cache_entries 4
      2 rest_client_transport_create_calls_total
      1 serviceaccount_invalid_legacy_auto_token_uses_total 0
      1 serviceaccount_legacy_auto_token_uses_total 0
      1 serviceaccount_legacy_manual_token_uses_total 0
      1 serviceaccount_legacy_tokens_total 0
      1 serviceaccount_stale_tokens_total 0
      1 serviceaccount_valid_tokens_total 323
     62 watch_cache_capacity
      1 watch_cache_capacity_increase_total
     26 workqueue_adds_total
     26 workqueue_depth
     26 workqueue_longest_running_processor_seconds
    286 workqueue_queue_duration_seconds_bucket
     26 workqueue_queue_duration_seconds_count
     26 workqueue_queue_duration_seconds_sum
     25 workqueue_retries_total
     26 workqueue_unfinished_work_seconds
    286 workqueue_work_duration_seconds_bucket
     26 workqueue_work_duration_seconds_count
     26 workqueue_work_duration_seconds_sum
```

### Try /metrics access from pod using current "default" Service Account

Create deployment:
```
$ k apply -f deployment.yaml 
service/http-server created
deployment.apps/http-server created
```

To request /metrics from api server target the kubernetes svc in default namespace (its the api server service):
```
$ k get svc kubernetes
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.255.0.1   <none>        443/TCP   56d

$ k get svc kubernetes -o yaml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: "2025-01-26T07:24:04Z"
  labels:
    component: apiserver
    provider: kubernetes
  name: kubernetes
  namespace: default
  resourceVersion: "230"
  uid: 30ed3202-ea1d-4a94-96a2-69ef2eb3e595
spec:
  clusterIP: 10.255.0.1
  clusterIPs:
  - 10.255.0.1
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: 6443
  sessionAffinity: None
  type: ClusterIP

$ k cluster-info
Kubernetes control plane is running at https://10.128.0.16:6443
CoreDNS is running at https://10.128.0.16:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```


Try to exec into pod to reach this service:
```
$ k exec -it http-server-5c4c6474b5-2jf8g -- /bin/bash

root@http-server-5c4c6474b5-2jf8g:~# find /var/run/
/var/run/
/var/run/lock
/var/run/secrets
/var/run/secrets/kubernetes.io
/var/run/secrets/kubernetes.io/serviceaccount
/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
/var/run/secrets/kubernetes.io/serviceaccount/token
/var/run/secrets/kubernetes.io/serviceaccount/namespace
/var/run/secrets/kubernetes.io/serviceaccount/..data
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/namespace
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/ca.crt
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/token
/var/run/adduser

root@http-server-5c4c6474b5-2jf8g:~# export TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

root@http-server-5c4c6474b5-2jf8g:~# curl -k --header "Authorization: Bearer $TOKEN" https://kubernetes.default/metrics
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/metrics\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
```


Check using auth can-i:
```
$ k auth whoami
ATTRIBUTE                                           VALUE
Username                                            kubernetes-admin
Groups                                              [kubeadm:cluster-admins system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [X509SHA256=8979e3d39e1d81acc4258cf55cea1933d20d32a0f05df627d7a4edfc04cfb345]

$ kubectl auth can-i get /metrics
yes

$ kubectl auth can-i get /metrics --as=kubernetes-admin --as-group=system:masters 
yes

$ kubectl auth can-i get /metrics --as=system:serviceaccount:default:default
no
```



# Service account with kube-api-server /metrics endpoint access


Initially tried to use Role and RoleBinding to namespace the role:
```
$ kubectl apply -f sa-monitoring.yaml 
serviceaccount/monitoring created
rolebinding.rbac.authorization.k8s.io/view-api-server-metrics created
The Role "view-api-server-metrics" is invalid: rules[0].nonResourceURLs: Invalid value: []string{"/metrics"}: namespaced rules cannot apply to non-resource URLs
```

So the rules have to use ClusterRole and ClusterRoleBinding, fix and apply again:
```
$ kubectl apply -f sa-monitoring.yaml 
serviceaccount/monitoring created
clusterrole.rbac.authorization.k8s.io/view-api-server-metrics created
clusterrolebinding.rbac.authorization.k8s.io/view-api-server-metrics created
```

Verify:
```
$ kubectl auth can-i get /metrics --as=system:serviceaccount:default:monitoring  
yes
```


Get sa token as a separate token for testing (default duration is 1 hour), see:
- https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/#without-kubectl-proxy:
- https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens

```
$ kubectl create token monitoring --duration 1h
eyJhbGciOiJSUzI1NiIsImtpZCI6Imp5R0QtQVNsNDE0V1hqR3RoM2lWMl9xNEtmZktfdHRZWEFnM191eVpvNnMifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzQyNzYwNjU2LCJpYXQiOjE3NDI3NTcwNTYsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiYmRmNzE0ZDgtM2M3YS00MTQ0LTlkMzktMjYwN2YyMWViMTFlIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6Im1vbml0b3JpbmciLCJ1aWQiOiJjOTkxYjhmNC0yMTA1LTRkMDAtYTM4NS0wZTY1ZjY0ZjVhNzMifX0sIm5iZiI6MTc0Mjc1NzA1Niwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6bW9uaXRvcmluZyJ9.tP7_qBg4fwy2H6_nnxImuZMraAAc3XDDYOnjvi5DJ1XSfDxkqFfj9O2KBBjADvRTqRXDGm-aMAmnoSDaq6hJzIcA_OipImKz6UvrJJU3bOJ5jkwZcN_aLRa8idAZegkbpHGwIiGZKHVJ-4cSxFhHZOCfUtGu3O7BJzQ1bcQ9cGMlN7fj94OfY8-dqQAHZu-FGpeKJ8O5DxPCUZC67fh3JYefx69siSXIHHpvDHC8WI38fnJ1Pb3etLYEMGK1kdlq10XYnr8cuJ1rMRpkv833fT7ibbAHpN1ag7evj74zUHNbW_2e2Vj8GEsKjZrE6o85XtzEtRmWpXsJEsuH3KDGAg

# decode with jwt.io
{
  "aud": [
    "https://kubernetes.default.svc.cluster.local"
  ],
  "exp": 1742759822,   // 2025-03-23T19:57:02Z
  "iat": 1742756222,   // 2025-03-23T18:57:02Z
  "iss": "https://kubernetes.default.svc.cluster.local",
  "jti": "4255d32d-db16-42fc-9c3c-be9d47314e0f",
  "kubernetes.io": {
    "namespace": "default",
    "serviceaccount": {
      "name": "monitoring",
      "uid": "c991b8f4-2105-4d00-a385-0e65f64f5a73"
    }
  },
  "nbf": 1742756222,   // 2025-03-23T18:57:02Z
  "sub": "system:serviceaccount:default:monitoring"
}
```

With this token requesting /metrics works (both from inside and from outside of cluster):
```
$ export TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6Imp5R0QtQVNsNDE0V1hqR3RoM2lWMl9xNEtmZktfdHRZWEFnM191eVpvNnMifQ.....Ag"


$ curl -k --header "Authorization: Bearer $TOKEN" https://kubernetes.default/metrics
# HELP aggregator_discovery_aggregation_count_total [ALPHA] Counter of number of times discovery was aggregated
# TYPE aggregator_discovery_aggregation_count_total counter
aggregator_discovery_aggregation_count_total 96
# HELP aggregator_unavailable_apiservice [ALPHA] Gauge of APIServices which are marked as unavailable broken down by APIService name.
# TYPE aggregator_unavailable_apiservice gauge
aggregator_unavailable_apiservice{name="v1."} 0
aggregator_unavailable_apiservice{name="v1.admissionregistration.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apiextensions.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apps"} 0


$ curl -k --header "Authorization: Bearer $TOKEN" https://158.160.61.136:6443/metrics
# HELP aggregator_discovery_aggregation_count_total [ALPHA] Counter of number of times discovery was aggregated
# TYPE aggregator_discovery_aggregation_count_total counter
aggregator_discovery_aggregation_count_total 100
# HELP aggregator_unavailable_apiservice [ALPHA] Gauge of APIServices which are marked as unavailable broken down by APIService name.
# TYPE aggregator_unavailable_apiservice gauge
aggregator_unavailable_apiservice{name="v1."} 0
aggregator_unavailable_apiservice{name="v1.admissionregistration.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apiextensions.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apps"} 0
```


Update deployments to use "monitoring" account and to scrape api-server metrics on pod startup and redeploy:
```
$ k apply -f deployment.yaml 
service/http-server unchanged
deployment.apps/http-server configured

$ k port-forward svc/http-server 9000:http-main
Forwarding from 127.0.0.1:9000 -> 8080
Forwarding from [::1]:9000 -> 8080

$ curl http://localhost:9000/
<!DOCTYPE HTML>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="metrics.html">metrics.html</a></li>
</ul>
<hr>
</body>
</html>

$ curl http://localhost:9000/metrics.html
# HELP aggregator_discovery_aggregation_count_total [ALPHA] Counter of number of times discovery was aggregated
# TYPE aggregator_discovery_aggregation_count_total counter
aggregator_discovery_aggregation_count_total 130
# HELP aggregator_unavailable_apiservice [ALPHA] Gauge of APIServices which are marked as unavailable broken down by APIService name.
# TYPE aggregator_unavailable_apiservice gauge
aggregator_unavailable_apiservice{name="v1."} 0
aggregator_unavailable_apiservice{name="v1.admissionregistration.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apiextensions.k8s.io"} 0
aggregator_unavailable_apiservice{name="v1.apps"} 0
aggregator_unavailable_apiservice{name="v1.authentication.k8s.io"} 0
```


### Create admin account "cd" in "default" namespace 

Plan to re-use "admin" cluster role with a namespaced RoleBinding.

Interesting that this role does not allow to create/delete namespaces.
```
$ k describe clusterrole admin
Name:         admin
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources                                       Non-Resource URLs  Resource Names  Verbs
  ---------                                       -----------------  --------------  -----
  leases.coordination.k8s.io                      []                 []              [create delete deletecollection get list patch update watch]
  rolebindings.rbac.authorization.k8s.io          []                 []              [create delete deletecollection get list patch update watch]
  roles.rbac.authorization.k8s.io                 []                 []              [create delete deletecollection get list patch update watch]
  configmaps                                      []                 []              [create delete deletecollection patch update get list watch]
  events                                          []                 []              [create delete deletecollection patch update get list watch]
  persistentvolumeclaims                          []                 []              [create delete deletecollection patch update get list watch]
  pods                                            []                 []              [create delete deletecollection patch update get list watch]
  replicationcontrollers/scale                    []                 []              [create delete deletecollection patch update get list watch]
  replicationcontrollers                          []                 []              [create delete deletecollection patch update get list watch]
  services                                        []                 []              [create delete deletecollection patch update get list watch]
  daemonsets.apps                                 []                 []              [create delete deletecollection patch update get list watch]
  deployments.apps/scale                          []                 []              [create delete deletecollection patch update get list watch]
  deployments.apps                                []                 []              [create delete deletecollection patch update get list watch]
  replicasets.apps/scale                          []                 []              [create delete deletecollection patch update get list watch]
  replicasets.apps                                []                 []              [create delete deletecollection patch update get list watch]
  statefulsets.apps/scale                         []                 []              [create delete deletecollection patch update get list watch]
  statefulsets.apps                               []                 []              [create delete deletecollection patch update get list watch]
  horizontalpodautoscalers.autoscaling            []                 []              [create delete deletecollection patch update get list watch]
  cronjobs.batch                                  []                 []              [create delete deletecollection patch update get list watch]
  jobs.batch                                      []                 []              [create delete deletecollection patch update get list watch]
  daemonsets.extensions                           []                 []              [create delete deletecollection patch update get list watch]
  deployments.extensions/scale                    []                 []              [create delete deletecollection patch update get list watch]
  deployments.extensions                          []                 []              [create delete deletecollection patch update get list watch]
  ingresses.extensions                            []                 []              [create delete deletecollection patch update get list watch]
  networkpolicies.extensions                      []                 []              [create delete deletecollection patch update get list watch]
  replicasets.extensions/scale                    []                 []              [create delete deletecollection patch update get list watch]
  replicasets.extensions                          []                 []              [create delete deletecollection patch update get list watch]
  replicationcontrollers.extensions/scale         []                 []              [create delete deletecollection patch update get list watch]
  ingresses.networking.k8s.io                     []                 []              [create delete deletecollection patch update get list watch]
  networkpolicies.networking.k8s.io               []                 []              [create delete deletecollection patch update get list watch]
  poddisruptionbudgets.policy                     []                 []              [create delete deletecollection patch update get list watch]
  deployments.apps/rollback                       []                 []              [create delete deletecollection patch update]
  deployments.extensions/rollback                 []                 []              [create delete deletecollection patch update]
  pods/eviction                                   []                 []              [create]
  serviceaccounts/token                           []                 []              [create]
  localsubjectaccessreviews.authorization.k8s.io  []                 []              [create]
  pods/attach                                     []                 []              [get list watch create delete deletecollection patch update]
  pods/exec                                       []                 []              [get list watch create delete deletecollection patch update]
  pods/portforward                                []                 []              [get list watch create delete deletecollection patch update]
  pods/proxy                                      []                 []              [get list watch create delete deletecollection patch update]
  secrets                                         []                 []              [get list watch create delete deletecollection patch update]
  services/proxy                                  []                 []              [get list watch create delete deletecollection patch update]
  bindings                                        []                 []              [get list watch]
  endpoints                                       []                 []              [get list watch]
  limitranges                                     []                 []              [get list watch]
  namespaces/status                               []                 []              [get list watch]
  namespaces                                      []                 []              [get list watch]
  persistentvolumeclaims/status                   []                 []              [get list watch]
  pods/log                                        []                 []              [get list watch]
  pods/status                                     []                 []              [get list watch]
  replicationcontrollers/status                   []                 []              [get list watch]
  resourcequotas/status                           []                 []              [get list watch]
  resourcequotas                                  []                 []              [get list watch]
  services/status                                 []                 []              [get list watch]
  controllerrevisions.apps                        []                 []              [get list watch]
  daemonsets.apps/status                          []                 []              [get list watch]
  deployments.apps/status                         []                 []              [get list watch]
  replicasets.apps/status                         []                 []              [get list watch]
  statefulsets.apps/status                        []                 []              [get list watch]
  horizontalpodautoscalers.autoscaling/status     []                 []              [get list watch]
  cronjobs.batch/status                           []                 []              [get list watch]
  jobs.batch/status                               []                 []              [get list watch]
  endpointslices.discovery.k8s.io                 []                 []              [get list watch]
  daemonsets.extensions/status                    []                 []              [get list watch]
  deployments.extensions/status                   []                 []              [get list watch]
  ingresses.extensions/status                     []                 []              [get list watch]
  replicasets.extensions/status                   []                 []              [get list watch]
  nodes.metrics.k8s.io                            []                 []              [get list watch]
  pods.metrics.k8s.io                             []                 []              [get list watch]
  ingresses.networking.k8s.io/status              []                 []              [get list watch]
  poddisruptionbudgets.policy/status              []                 []              [get list watch]
  serviceaccounts                                 []                 []              [impersonate create delete deletecollection patch update get list watch]

$ kubectl apply -f sa-cd.yaml 
serviceaccount/cd created
rolebinding.rbac.authorization.k8s.io/admin-cd created

$ kubectl create token cd --duration 12h
eyJhbGciOiJSUzI1NiIsImtpZCI6Imp5R0QtQVNsNDE0V1hqR3RoM2lWMl9xNEtmZktfdHRZWEFnM191eVpvNnMifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzQyODAzMjg2LCJpYXQiOjE3NDI3NjAwODYsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiOTk4MWExZTgtOGZlMi00MDJmLTk0NzItZTM5NjNhZmQ0NjRmIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImNkIiwidWlkIjoiZWZhNTU5ZjYtOWUwOS00MzY2LTg0MjUtMzE5Yzc1YzFmOGQ1In19LCJuYmYiOjE3NDI3NjAwODYsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmNkIn0.XM2oo8xUmFiiZ5BcQI3vvtyyegvUuF4W7LChfcE1CVvjCsUnI0V969cndfL2dKyAsQGext6uHDDL26nX79fRolam8aW5jQZexwg-_uGoT-eozJbBde5XzgYEH_OzAWlMeCzwAy-OI9AC-5DQa9DXhmeNEz0RGlRDPMh5EPmBbkRJ73NfXVgWkz4jcwyG3Bw_BEH5ezVg4oZ9QweqZDmmdydoL1t-34IJuzSQcf62QnD4owOd4uzEXdT1zkZmBNXvO-WKVhAOh2h1hUOzUkCR22b-u-2dTsmog5KRDa1Gum6G2KvSjtZy-PiD8pCUZjAcj6cEixRnetyzSThLUCQFtQ

# jwt.io analysis, token lasts 12h
{
  "aud": [
    "https://kubernetes.default.svc.cluster.local"
  ],
  "exp": 1742803286,     // 2025-03-24T08:01:26Z
  "iat": 1742760086,     // 2025-03-23T20:01:26Z
  "iss": "https://kubernetes.default.svc.cluster.local",
  "jti": "9981a1e8-8fe2-402f-9472-e3963afd464f",
  "kubernetes.io": {
    "namespace": "default",
    "serviceaccount": {
      "name": "cd",
      "uid": "efa559f6-9e09-4366-8425-319c75c1f8d5"
    }
  },
  "nbf": 1742760086,     // 2025-03-23T20:01:26Z
  "sub": "system:serviceaccount:default:cd"
}
```


Verify that kubeconfig works:
```
~/.kube$ cp kubeconfig.yaml config 

~/.kube$ k get pods
NAME                              READY   STATUS    RESTARTS   AGE
http-server-678f8f4bb7-xr46l      1/1     Running   0          36m
metrics-server-6f665c9d54-x8kvh   1/1     Running   0          148m

~/.kube$ k get pods -A
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:default:cd" cannot list resource "pods" in API group "" at the cluster scope

~/.kube$ k auth whoami
ATTRIBUTE                                           VALUE
Username                                            system:serviceaccount:default:cd
UID                                                 efa559f6-9e09-4366-8425-319c75c1f8d5
Groups                                              [system:serviceaccounts system:serviceaccounts:default system:authenticated]
Extra: authentication.kubernetes.io/credential-id   [JTI=e4c9d84c-7b97-431b-ac41-be613bc3ba57]
```

To check without creating kubeconfig, see https://kubernetes.io/docs/reference/access-authn-authz/authentication/#option-2-use-the-token-option:
```
$ kubectl --token=eyJhbGciOiJSUzI1NiIsImtpZCI6Imp5R0QtQVNsNDE0V1hqR3RoM2lWMl9xNEtmZktfdHRZWEFnM191eVpvNnMifQ...tQ get nodes
```

At this point it turned out that kubernetes already has a default monitoring cluster role (in addition to the one created by hand):
```
$ k describe clusterroles 
...
Name:         system:monitoring
Labels:       kubernetes.io/bootstrapping=rbac-defaults
Annotations:  rbac.authorization.kubernetes.io/autoupdate: true
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
             [/healthz/*]       []              [get]
             [/healthz]         []              [get]
             [/livez/*]         []              [get]
             [/livez]           []              [get]
             [/metrics/slis]    []              [get]
             [/metrics]         []              [get]
             [/readyz/*]        []              [get]
             [/readyz]          []              [get]

Name:         view-api-server-metrics
Labels:       <none>
Annotations:  <none>
PolicyRule:
  Resources  Non-Resource URLs  Resource Names  Verbs
  ---------  -----------------  --------------  -----
             [/metrics]         []              [get]

```


# Install metrics-server

Initially confused /metrics api with metrics.k8s.io api group that provides resource monitoring for Horizontal / Vertical pod autoscalers. 

Below are instructions regarding its install.

### About metrics.k8s.io api

Metrics pipeline overview: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/

Metrics server implementation to provide `metrics.k8s.io` api: https://github.com/kubernetes-sigs/metrics-server

Metrics format exposed by metrics-server: https://kubernetes.io/docs/reference/instrumentation/metrics/

See also: https://kubernetes.io/docs/reference/external-api/metrics.v1beta1/


Check if metrics api is already installed:
```
$ k api-resources -o wide
NAME                                SHORTNAMES   APIVERSION                        NAMESPACED   KIND                               VERBS                                                        CATEGORIES
bindings                                         v1                                true         Binding                            create                                                       
componentstatuses                   cs           v1                                false        ComponentStatus                    get,list                                                     
configmaps                          cm           v1                                true         ConfigMap                          create,delete,deletecollection,get,list,patch,update,watch   
endpoints                           ep           v1                                true         Endpoints                          create,delete,deletecollection,get,list,patch,update,watch   
events                              ev           v1                                true         Event                              create,delete,deletecollection,get,list,patch,update,watch   
limitranges                         limits       v1                                true         LimitRange                         create,delete,deletecollection,get,list,patch,update,watch   
namespaces                          ns           v1                                false        Namespace                          create,delete,get,list,patch,update,watch                    
nodes                               no           v1                                false        Node                               create,delete,deletecollection,get,list,patch,update,watch   
persistentvolumeclaims              pvc          v1                                true         PersistentVolumeClaim              create,delete,deletecollection,get,list,patch,update,watch   
persistentvolumes                   pv           v1                                false        PersistentVolume                   create,delete,deletecollection,get,list,patch,update,watch   
pods                                po           v1                                true         Pod                                create,delete,deletecollection,get,list,patch,update,watch   all
podtemplates                                     v1                                true         PodTemplate                        create,delete,deletecollection,get,list,patch,update,watch   
replicationcontrollers              rc           v1                                true         ReplicationController              create,delete,deletecollection,get,list,patch,update,watch   all
resourcequotas                      quota        v1                                true         ResourceQuota                      create,delete,deletecollection,get,list,patch,update,watch   
secrets                                          v1                                true         Secret                             create,delete,deletecollection,get,list,patch,update,watch   
serviceaccounts                     sa           v1                                true         ServiceAccount                     create,delete,deletecollection,get,list,patch,update,watch   
services                            svc          v1                                true         Service                            create,delete,deletecollection,get,list,patch,update,watch   all
mutatingwebhookconfigurations                    admissionregistration.k8s.io/v1   false        MutatingWebhookConfiguration       create,delete,deletecollection,get,list,patch,update,watch   api-extensions
validatingadmissionpolicies                      admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicy          create,delete,deletecollection,get,list,patch,update,watch   api-extensions
validatingadmissionpolicybindings                admissionregistration.k8s.io/v1   false        ValidatingAdmissionPolicyBinding   create,delete,deletecollection,get,list,patch,update,watch   api-extensions
validatingwebhookconfigurations                  admissionregistration.k8s.io/v1   false        ValidatingWebhookConfiguration     create,delete,deletecollection,get,list,patch,update,watch   api-extensions
customresourcedefinitions           crd,crds     apiextensions.k8s.io/v1           false        CustomResourceDefinition           create,delete,deletecollection,get,list,patch,update,watch   api-extensions
apiservices                                      apiregistration.k8s.io/v1         false        APIService                         create,delete,deletecollection,get,list,patch,update,watch   api-extensions
controllerrevisions                              apps/v1                           true         ControllerRevision                 create,delete,deletecollection,get,list,patch,update,watch   
daemonsets                          ds           apps/v1                           true         DaemonSet                          create,delete,deletecollection,get,list,patch,update,watch   all
deployments                         deploy       apps/v1                           true         Deployment                         create,delete,deletecollection,get,list,patch,update,watch   all
replicasets                         rs           apps/v1                           true         ReplicaSet                         create,delete,deletecollection,get,list,patch,update,watch   all
statefulsets                        sts          apps/v1                           true         StatefulSet                        create,delete,deletecollection,get,list,patch,update,watch   all
selfsubjectreviews                               authentication.k8s.io/v1          false        SelfSubjectReview                  create                                                       
tokenreviews                                     authentication.k8s.io/v1          false        TokenReview                        create                                                       
localsubjectaccessreviews                        authorization.k8s.io/v1           true         LocalSubjectAccessReview           create                                                       
selfsubjectaccessreviews                         authorization.k8s.io/v1           false        SelfSubjectAccessReview            create                                                       
selfsubjectrulesreviews                          authorization.k8s.io/v1           false        SelfSubjectRulesReview             create                                                       
subjectaccessreviews                             authorization.k8s.io/v1           false        SubjectAccessReview                create                                                       
horizontalpodautoscalers            hpa          autoscaling/v2                    true         HorizontalPodAutoscaler            create,delete,deletecollection,get,list,patch,update,watch   all
cronjobs                            cj           batch/v1                          true         CronJob                            create,delete,deletecollection,get,list,patch,update,watch   all
jobs                                             batch/v1                          true         Job                                create,delete,deletecollection,get,list,patch,update,watch   all
certificatesigningrequests          csr          certificates.k8s.io/v1            false        CertificateSigningRequest          create,delete,deletecollection,get,list,patch,update,watch   
leases                                           coordination.k8s.io/v1            true         Lease                              create,delete,deletecollection,get,list,patch,update,watch   
endpointslices                                   discovery.k8s.io/v1               true         EndpointSlice                      create,delete,deletecollection,get,list,patch,update,watch   
events                              ev           events.k8s.io/v1                  true         Event                              create,delete,deletecollection,get,list,patch,update,watch   
wasmplugins                                      extensions.istio.io/v1alpha1      true         WasmPlugin                         delete,deletecollection,get,list,patch,create,update,watch   istio-io,extensions-istio-io
flowschemas                                      flowcontrol.apiserver.k8s.io/v1   false        FlowSchema                         create,delete,deletecollection,get,list,patch,update,watch   
prioritylevelconfigurations                      flowcontrol.apiserver.k8s.io/v1   false        PriorityLevelConfiguration         create,delete,deletecollection,get,list,patch,update,watch   
kialis                                           kiali.io/v1alpha1                 true         Kiali                              delete,deletecollection,get,list,patch,create,update,watch   
destinationrules                    dr           networking.istio.io/v1            true         DestinationRule                    delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
envoyfilters                                     networking.istio.io/v1alpha3      true         EnvoyFilter                        delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
gateways                            gw           networking.istio.io/v1            true         Gateway                            delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
proxyconfigs                                     networking.istio.io/v1beta1       true         ProxyConfig                        delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
serviceentries                      se           networking.istio.io/v1            true         ServiceEntry                       delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
sidecars                                         networking.istio.io/v1            true         Sidecar                            delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
virtualservices                     vs           networking.istio.io/v1            true         VirtualService                     delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
workloadentries                     we           networking.istio.io/v1            true         WorkloadEntry                      delete,deletecollection,get,list,patch,create,update,watch   istio-io,networking-istio-io
ingressclasses                                   networking.k8s.io/v1              false        IngressClass                       create,delete,deletecollection,get,list,patch,update,watch   
ingresses                           ing          networking.k8s.io/v1              true         Ingress                            create,delete,deletecollection,get,list,patch,update,watch   
networkpolicies                     netpol       networking.k8s.io/v1              true         NetworkPolicy                      create,delete,deletecollection,get,list,patch,update,watch   
runtimeclasses                                   node.k8s.io/v1                    false        RuntimeClass                       create,delete,deletecollection,get,list,patch,update,watch   
poddisruptionbudgets                pdb          policy/v1                         true         PodDisruptionBudget                create,delete,deletecollection,get,list,patch,update,watch   
clusterrolebindings                              rbac.authorization.k8s.io/v1      false        ClusterRoleBinding                 create,delete,deletecollection,get,list,patch,update,watch   
clusterroles                                     rbac.authorization.k8s.io/v1      false        ClusterRole                        create,delete,deletecollection,get,list,patch,update,watch   
rolebindings                                     rbac.authorization.k8s.io/v1      true         RoleBinding                        create,delete,deletecollection,get,list,patch,update,watch   
roles                                            rbac.authorization.k8s.io/v1      true         Role                               create,delete,deletecollection,get,list,patch,update,watch   
priorityclasses                     pc           scheduling.k8s.io/v1              false        PriorityClass                      create,delete,deletecollection,get,list,patch,update,watch   
authorizationpolicies               ap           security.istio.io/v1              true         AuthorizationPolicy                delete,deletecollection,get,list,patch,create,update,watch   istio-io,security-istio-io
peerauthentications                 pa           security.istio.io/v1              true         PeerAuthentication                 delete,deletecollection,get,list,patch,create,update,watch   istio-io,security-istio-io
requestauthentications              ra           security.istio.io/v1              true         RequestAuthentication              delete,deletecollection,get,list,patch,create,update,watch   istio-io,security-istio-io
csidrivers                                       storage.k8s.io/v1                 false        CSIDriver                          create,delete,deletecollection,get,list,patch,update,watch   
csinodes                                         storage.k8s.io/v1                 false        CSINode                            create,delete,deletecollection,get,list,patch,update,watch   
csistoragecapacities                             storage.k8s.io/v1                 true         CSIStorageCapacity                 create,delete,deletecollection,get,list,patch,update,watch   
storageclasses                      sc           storage.k8s.io/v1                 false        StorageClass                       create,delete,deletecollection,get,list,patch,update,watch   
volumeattachments                                storage.k8s.io/v1                 false        VolumeAttachment                   create,delete,deletecollection,get,list,patch,update,watch   
telemetries                         telemetry    telemetry.istio.io/v1             true         Telemetry                          delete,deletecollection,get,list,patch,create,update,watch   istio-io,telemetry-istio-io
```

There are kiali and istio resources, but unfortunatelly no metrics api resource.

Verify that kubectl top fails:
```
$ k get pods -n default
NAME                           READY   STATUS    RESTARTS   AGE
http-server-5c4c6474b5-2jf8g   1/1     Running   0          34m

$ k top pod http-server-5c4c6474b5-2jf8g
error: Metrics API not available

$ k top node worker1
error: Metrics API not available
```


### Install metrics-server:

Separate cAdvisor install is not necessary. By default, Kubernetes fetches node summary metrics data using an embedded cAdvisor
that runs within the kubelet. see: https://kubernetes.io/docs/reference/instrumentation/node-metrics/#summary-api-source

Also some container runtimes supports statistics access via Container Runtime Interface (CRI), see: https://kubernetes.io/docs/reference/instrumentation/cri-pod-container-metrics/


Helm install, see: https://github.com/kubernetes-sigs/metrics-server:
```
# helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
"metrics-server" has been added to your repositories

# helm upgrade --install metrics-server metrics-server/metrics-server
Release "metrics-server" does not exist. Installing it now.
NAME: metrics-server
LAST DEPLOYED: Sun Mar 23 06:41:50 2025
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
***********************************************************************
* Metrics Server                                                      *
***********************************************************************
  Chart version: 3.12.2
  App version:   0.7.2
  Image tag:     registry.k8s.io/metrics-server/metrics-server:v0.7.2
***********************************************************************

# k get pods -A
NAMESPACE      NAME                              READY   STATUS    RESTARTS       AGE
default        http-server-5c4c6474b5-2jf8g      1/1     Running   0              63m
default        metrics-server-6fdb59879c-lgpl5   0/1     Running   0              29s
kube-flannel   kube-flannel-ds-hjwfh             1/1     Running   7 (12h ago)    6d11h
kube-flannel   kube-flannel-ds-q2gl4             1/1     Running   20 (12h ago)   6d12h
kube-flannel   kube-flannel-ds-sq6s7             1/1     Running   7 (12h ago)    6d11h
kube-flannel   kube-flannel-ds-sx6qk             1/1     Running   6 (12h ago)    6d11h
kube-system    coredns-7c65d6cfc9-gmzxw          1/1     Running   4 (12h ago)    6d11h
kube-system    coredns-7c65d6cfc9-pk4xt          1/1     Running   16 (12h ago)   25d
kube-system    etcd-master                       1/1     Running   22 (12h ago)   55d
kube-system    kube-apiserver-master             1/1     Running   22 (12h ago)   55d
kube-system    kube-controller-manager-master    1/1     Running   23 (12h ago)   55d
kube-system    kube-proxy-bp57z                  1/1     Running   9 (12h ago)    9d
kube-system    kube-proxy-hkklk                  1/1     Running   8 (12h ago)    9d
kube-system    kube-proxy-x4qcl                  1/1     Running   5 (23h ago)    6d12h
kube-system    kube-proxy-z5ztj                  1/1     Running   6 (12h ago)    6d12h
kube-system    kube-scheduler-master             1/1     Running   18 (12h ago)   25d

k logs metrics-server-6fdb59879c-lgpl5
I0323 06:43:01.775649       1 server.go:191] "Failed probe" probe="metric-storage-ready" err="no metrics to serve"
I0323 06:43:11.775612       1 server.go:191] "Failed probe" probe="metric-storage-ready" err="no metrics to serve"
E0323 06:43:14.880361       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.3:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.3 because it doesn't contain any IP SANs" node="worker3"
E0323 06:43:14.883126       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.16:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.16 because it doesn't contain any IP SANs" node="master"
E0323 06:43:14.889181       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.26:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.26 because it doesn't contain any IP SANs" node="worker2"
E0323 06:43:14.904774       1 scraper.go:149] "Failed to scrape node" err="Get \"https://10.128.0.25:10250/metrics/resource\": tls: failed to verify certificate: x509: cannot validate certificate for 10.128.0.25 because it doesn't contain any IP SANs" node="worker1"
```

Problems with startup of metrics-server. Disable tls verification and re-install, see https://github.com/kubernetes-sigs/metrics-server?tab=readme-ov-file#configuration:
```
$ helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
"metrics-server" has been added to your repositories

$ helm search repo metrics-server
NAME                         	CHART VERSION	APP VERSION	DESCRIPTION                                       
bitnami/metrics-server       	7.4.1        	0.7.2      	Metrics Server aggregates resource usage data, ...
metrics-server/metrics-server	3.12.2       	0.7.2      	Metrics Server is a scalable, efficient source ...

$ helm pull metrics-server/metrics-server

$ unp metrics-server-3.12.2.tgz 
metrics-server/Chart.yaml
metrics-server/values.yaml
metrics-server/templates/NOTES.txt
metrics-server/templates/_helpers.tpl
metrics-server/templates/apiservice.yaml
metrics-server/templates/clusterrole-aggregated-reader.yaml
metrics-server/templates/clusterrole-nanny.yaml
metrics-server/templates/clusterrole.yaml
metrics-server/templates/clusterrolebinding-auth-delegator.yaml
metrics-server/templates/clusterrolebinding-nanny.yaml
metrics-server/templates/clusterrolebinding.yaml
metrics-server/templates/configmaps-nanny.yaml
metrics-server/templates/deployment.yaml
metrics-server/templates/pdb.yaml
metrics-server/templates/psp.yaml
metrics-server/templates/role-nanny.yaml
metrics-server/templates/rolebinding-nanny.yaml
metrics-server/templates/rolebinding.yaml
metrics-server/templates/service.yaml
metrics-server/templates/serviceaccount.yaml
metrics-server/templates/servicemonitor.yaml
metrics-server/.helmignore
metrics-server/CHANGELOG.md
metrics-server/README.md
metrics-server/RELEASE.md
metrics-server/ci/ci-values.yaml

$ less metrics-server/values.yaml
```

Clean re-install:
```
$ helm upgrade --install metrics-server metrics-server/metrics-server -f values-metrics-server.yaml 
Release "metrics-server" has been upgraded. Happy Helming!
NAME: metrics-server
LAST DEPLOYED: Sun Mar 23 11:59:19 2025
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
***********************************************************************
* Metrics Server                                                      *
***********************************************************************
  Chart version: 3.12.2
  App version:   0.7.2
  Image tag:     registry.k8s.io/metrics-server/metrics-server:v0.7.2
***********************************************************************

$ k get pods -A
NAMESPACE      NAME                              READY   STATUS    RESTARTS       AGE
default        http-server-5c4c6474b5-2jf8g      1/1     Running   0              81m
default        metrics-server-6f665c9d54-nrj7b   1/1     Running   0              66s
kube-flannel   kube-flannel-ds-hjwfh             1/1     Running   7 (12h ago)    6d12h
kube-flannel   kube-flannel-ds-q2gl4             1/1     Running   20 (12h ago)   6d13h
kube-flannel   kube-flannel-ds-sq6s7             1/1     Running   7 (12h ago)    6d11h
kube-flannel   kube-flannel-ds-sx6qk             1/1     Running   6 (12h ago)    6d12h
kube-system    coredns-7c65d6cfc9-gmzxw          1/1     Running   4 (12h ago)    6d12h
kube-system    coredns-7c65d6cfc9-pk4xt          1/1     Running   16 (12h ago)   25d
kube-system    etcd-master                       1/1     Running   22 (12h ago)   55d
kube-system    kube-apiserver-master             1/1     Running   22 (12h ago)   55d
kube-system    kube-controller-manager-master    1/1     Running   23 (12h ago)   55d
kube-system    kube-proxy-bp57z                  1/1     Running   9 (12h ago)    9d
kube-system    kube-proxy-hkklk                  1/1     Running   8 (12h ago)    9d
kube-system    kube-proxy-x4qcl                  1/1     Running   5 (23h ago)    6d13h
kube-system    kube-proxy-z5ztj                  1/1     Running   6 (12h ago)    6d13h
kube-system    kube-scheduler-master             1/1     Running   18 (12h ago)   25d

$ k get svc -A
NAMESPACE     NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
default       http-server      ClusterIP   10.255.8.210     <none>        8080/TCP                 11h
default       kubernetes       ClusterIP   10.255.0.1       <none>        443/TCP                  55d
default       metrics-server   ClusterIP   10.255.193.237   <none>        443/TCP                  20m
kube-system   kube-dns         ClusterIP   10.255.0.10      <none>        53/UDP,53/TCP,9153/TCP   55d
```


Verify kubectl top works and ferify /apis/metrics.k8s.io also work (note that v1beta1 is taken from "kubectl api-resources" and this api is self-declaratory):
```
$ k top node worker1
NAME      CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
worker1   19m          0%       585Mi           7%

$ k get --raw /apis/metrics.k8s.io/ | jq
{
  "kind": "APIGroup",
  "apiVersion": "v1",
  "name": "metrics.k8s.io",
  "versions": [
    {
      "groupVersion": "metrics.k8s.io/v1beta1",
      "version": "v1beta1"
    }
  ],
  "preferredVersion": {
    "groupVersion": "metrics.k8s.io/v1beta1",
    "version": "v1beta1"
  }
}

$ k get --raw /apis/metrics.k8s.io/v1beta1/ | jq
{
  "kind": "APIResourceList",
  "apiVersion": "v1",
  "groupVersion": "metrics.k8s.io/v1beta1",
  "resources": [
    {
      "name": "nodes",
      "singularName": "",
      "namespaced": false,
      "kind": "NodeMetrics",
      "verbs": [
        "get",
        "list"
      ]
    },
    {
      "name": "pods",
      "singularName": "",
      "namespaced": true,
      "kind": "PodMetrics",
      "verbs": [
        "get",
        "list"
      ]
    }
  ]
}

$ k get --raw /apis/metrics.k8s.io/v1beta1/nodes/worker1 | jq
{
  "kind": "NodeMetrics",
  "apiVersion": "metrics.k8s.io/v1beta1",
  "metadata": {
    "name": "worker1",
    "creationTimestamp": "2025-03-23T18:13:27Z",
    "labels": {
      "beta.kubernetes.io/arch": "amd64",
      "beta.kubernetes.io/os": "linux",
      "kubernetes.io/arch": "amd64",
      "kubernetes.io/hostname": "worker1",
      "kubernetes.io/os": "linux"
    }
  },
  "timestamp": "2025-03-23T18:13:18Z",
  "window": "22.029s",
  "usage": {
    "cpu": "14958645n",
    "memory": "413432Ki"
  }
}
```

Note: docs state that right now kubelet is exposing metric unsecurely: https://github.com/kubernetes-sigs/metrics-server/blob/master/FAQ.md#how-to-run-metrics-server-securely

However get "401 Unauthorized" when trying metrics without auth, so maybe its ok:
```
$ curl -v -k https://158.160.61.136:10250/metrics/resource
*   Trying 158.160.61.136:10250...
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Request CERT (13):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Certificate (11):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256 / x25519 / RSASSA-PSS
* ALPN: server accepted h2
* Server certificate:
*  subject: CN=master@1737876213
*  start date: Jan 26 06:23:33 2025 GMT
*  expire date: Jan 26 06:23:33 2026 GMT
*  issuer: CN=master-ca@1737876213
*  SSL certificate verify result: self-signed certificate in certificate chain (19), continuing anyway.
*   Certificate level 0: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
*   Certificate level 1: Public key type RSA (2048/112 Bits/secBits), signed using sha256WithRSAEncryption
* Connected to 158.160.61.136 (158.160.61.136) port 10250
* using HTTP/2
* [HTTP/2] [1] OPENED stream for https://158.160.61.136:10250/metrics/resource
* [HTTP/2] [1] [:method: GET]
* [HTTP/2] [1] [:scheme: https]
* [HTTP/2] [1] [:authority: 158.160.61.136:10250]
* [HTTP/2] [1] [:path: /metrics/resource]
* [HTTP/2] [1] [user-agent: curl/8.12.1]
* [HTTP/2] [1] [accept: */*]
> GET /metrics/resource HTTP/2
> Host: 158.160.61.136:10250
> User-Agent: curl/8.12.1
> Accept: */*
> 
* Request completely sent off
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
< HTTP/2 401 
< content-type: text/plain; charset=utf-8
< content-length: 12
< date: Sun, 23 Mar 2025 07:08:45 GMT
< 
* Connection #0 to host 158.160.61.136 left intact
Unauthorized%
```


### Try kube api server access from pod using "default" Service Account

Create deployment:
```
$ k apply -f deployment.yaml 
service/http-server created
deployment.apps/http-server created
```

Try to access kube api server with curl from debug container:
```
$ k debug -it --profile=sysadmin --image=nicolaka/netshoot:v0.13 -n default --target=server-container http-server-5c4c6474b5-2jf8g
                                         
http-server-5c4c6474b5-2jf8g  ~  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
cat: can't open '/var/run/secrets/kubernetes.io/serviceaccount/token': No such file or directory

http-server-5c4c6474b5-2jf8g  ~  ps   
PID   USER     TIME  COMMAND
    1 root      0:00 python -m http.server 8080 --directory /opt
    7 root      0:01 zsh
   93 root      0:00 ps
http-server-5c4c6474b5-2jf8g  ~  ls -la /proc/1/root/var/run/  
total 8
drwxr-xr-x    2 root     root          4096 Jan 26  2024 .
drwxr-xr-x    1 root     root          4096 Mar 23 05:43 ..

http-server-5c4c6474b5-2jf8g  ~  ls -la /var/run
total 8
drwxr-xr-x    2 root     root          4096 Jan 26  2024 .
drwxr-xr-x    1 root     root          4096 Mar 23 05:47 ..
```

However the debug container does not get kube token secret installed and looks like it can not access pod's secret token either.

Try to exec into pod:
```
$ k exec -it http-server-5c4c6474b5-2jf8g -- /bin/bash

root@http-server-5c4c6474b5-2jf8g:~# find /var/run/
/var/run/
/var/run/lock
/var/run/secrets
/var/run/secrets/kubernetes.io
/var/run/secrets/kubernetes.io/serviceaccount
/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
/var/run/secrets/kubernetes.io/serviceaccount/token
/var/run/secrets/kubernetes.io/serviceaccount/namespace
/var/run/secrets/kubernetes.io/serviceaccount/..data
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/namespace
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/ca.crt
/var/run/secrets/kubernetes.io/serviceaccount/..2025_03_23_05_39_03.2040266637/token
/var/run/adduser

root@http-server-5c4c6474b5-2jf8g:~# export TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

root@http-server-5c4c6474b5-2jf8g:~# curl -k --header "Authorization: Bearer $TOKEN" https://metrics-server.default/metrics
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:serviceaccount:default:default\" cannot get path \"/metrics\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
```

