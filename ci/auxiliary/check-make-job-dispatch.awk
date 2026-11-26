# Inspect the local ARM64 control flow printed by otool for JobExec only.
function fail(reason) {
    print "FAIL: " reason > "/dev/stderr"
    exit 1
}

function address(s) {
    sub(/^0x/, "", s)
    sub(/^0+/, "", s)
    return s
}

function hex(s,    i, value) {
    for (i = 1; i <= length(s); i++)
        value = 16 * value + index("0123456789abcdef", substr(s, i, 1)) - 1
    return value
}

function following(i) {
    if (i + 1 > n || hex(pc[i + 1]) != hex(pc[i]) + 4)
        fail("noncontiguous instruction after 0x" pc[i])
    return i + 1
}

function destination(i) {
    if (!(target[i] in at))
        fail("branch leaves JobExec before dispatch at 0x" pc[i])
    return at[target[i]]
}

function after_fork(i,    next_i) {
    next_i = following(i)
    return op[next_i] == "b" ? destination(next_i) : next_i
}

function error_path(i, handler,    message, steps) {
    # A straight-line error block may jump to a shared error call.
    for (steps = 0; steps < n; steps++) {
        if (line[i] ~ /literal pool for: "Cannot vfork: %s"/)
            message = 1
        if (op[i] == "bl" && symbol[i] == handler)
            return handler != "_Punt" || message
        if (op[i] ~ /^(b\.[a-z]+|cbn?z|tbn?z|br.*|ret.*)$/ ||
            symbol[i] ~ /^(_Punt|_ios_execv|_execError|_Trace_Log|_ios_exit)$/)
            return 0
        i = op[i] == "b" ? destination(i) : following(i)
    }
    return 0
}

function io_error_branch(i, dest) {
    # Only a branch on a redirection call's -1 return may skip dispatch.
    return op[i] == "b.eq" && line[i - 1] ~ /[[:space:]]cmn[[:space:]]+[wx]0, #0x1$/ &&
        op[i - 2] == "bl" && error_path(dest, "_execError")
}

function success_path(i,    dest) {
    if (seen[i] == 1)
        fail("cycle in JobExec before dispatch at 0x" pc[i])
    if (seen[i] == 2)
        return
    seen[i] = 1
    if (op[i] == "bl" && symbol[i] == "_ios_execv") {
        dispatched = 1
    } else if (symbol[i] ~ /^(_Trace_Log|_Punt|_execError|_ios_exit)$/ || op[i] ~ /^(br.*|ret.*)$/) {
        fail("non-error path bypasses ios_execv at 0x" pc[i])
    } else if (op[i] == "b") {
        success_path(destination(i))
    } else {
        if (op[i] ~ /^(b\.[a-z]+|cbn?z|tbn?z)$/) {
            dest = destination(i)
            if (!io_error_branch(i, dest))
                success_path(dest)
        }
        success_path(following(i))
    }
    seen[i] = 2
}

/^_JobExec:$/ { in_job = 1; next }
/^_[^[:space:]]+:$/ { in_job = 0 }
in_job && /^[[:xdigit:]]+[[:space:]]/ {
    pc[++n] = address($1)
    at[pc[n]] = n
    op[n] = $2
    line[n] = $0
    if ($0 ~ /; symbol stub for: /)
        symbol[n] = $NF
    else if ($2 == "bl" || $2 == "b")
        symbol[n] = $3
    if (op[n] ~ /^(b|b\.[a-z]+|cbn?z|tbn?z)$/)
        target[n] = address($NF)
    if ($2 == "bl" && symbol[n] == "_fork") {
        fork_index = n
        forks++
    }
    if ($2 == "bl" && symbol[n] == "_vfork") {
        vfork_index = n
        vforks++
    }
}

END {
    if (forks != 1 || vforks != 1)
        fail("expected one fork and one vfork call in JobExec")
    compare = after_fork(fork_index)
    if (compare != after_fork(vfork_index))
        fail("fork and vfork do not join at the same return check")
    # The current compiler saves x0 for bookkeeping before checking w0.
    if (line[compare] ~ /[[:space:]]mov[[:space:]]+x[0-9]+, x0$/)
        compare = following(compare)
    branch = following(compare)
    if (line[compare] !~ /[[:space:]]cmn[[:space:]]+w0, #0x1$/ || op[branch] != "b.eq")
        fail("fork return must be compared to -1 immediately before b.eq")
    if (!error_path(destination(branch), "_Punt"))
        fail("-1 fork result does not lead to the Cannot vfork error")
    success_path(following(branch))
    if (!dispatched)
        fail("non-error fork result cannot reach ios_execv")
    print "PASS: both fork returns join at the -1 check; failure reaches Punt, and the successful path reaches ios_execv"
}
