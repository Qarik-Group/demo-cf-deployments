source output.sh

log_info "We are testing" log_info "function"
log_result "We are testing" log_result "function"
log_warn "We are testing" log_warn "function"
log_ok 
log_not_ok
log_active "We are testing" log_active with log_ok "function"
sleep 3
log_ok
log_active "We are testing" log_active with log_not_ok "function"
sleep 3
log_not_ok
log_active "We are testing" log_active with log_not_ok with a reason "function"
sleep 3
log_not_ok "Here is the for " the failure
# export -f enable_debug
# export -f enable_trace
# export -f debug
# export -f trace
