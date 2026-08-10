---
name: network-troubleshooting-standards
description: Reactive network fault diagnosis method — bisecting the path, forming a falsifiable hypothesis and proving root cause. Use when something "doesn't connect", is intermittent, slow or hangs mid-transfer and you are reaching for ping, traceroute, mtr --report, ss -tin, ip route get, ip neigh, arping, ethtool -S, tshark or dumpcap, capturing pcap simultaneously at both endpoints, curl -v --resolve, openssl s_client, nc -zv, socat, iperf3 -R with -P and -u, /proc/net/nf_conntrack and ephemeral port exhaustion, PMTU blackhole with ICMP fragmentation-needed filtered, TIME_WAIT and listen-backlog overflow, keepalive versus middlebox idle timeout, IP address conflict or MAC flapping, broadcast storms and layer-2 loops, ARP/ND caches, IPv6 preferred over working IPv4 and Happy Eyeballs, TLS-inspecting proxies, tail-latency percentiles versus averages, bpftrace, bcc tools, pwru, hubble observe, kubectl debug --image=nicolaka/netshoot across pod and node netns, or VPC flow logs — and when you must record what was tried, what it proved and why the fix was the fix.
---

# Network diagnosis standards — the method, not the commands

Criteria verified as of **August 2026**. Re-verify on the web before committing to anything (§8).

## 1. Scope and triggers

Applies when **something no longer works and you have to find out why**: a method by layers and by
bisection, formulation of falsifiable hypotheses, canonical checking sequence
(resolution → outbound → return → acceptance by the application), choosing a tool by question and
**which lie each one tells**, a catalogue of the usual suspects with their characteristic symptom,
honest measurement of latency/loss/jitter, diagnosis in containers, Kubernetes, clouds and
overlays, and the discipline of recording and closing with a **proven root cause**.

Triggers: "it does not connect", "it is slow", "it is intermittent", "it drops every X minutes", "it works from here
but not from there", "it hangs while transferring", "it connects but does not load", `ping`, `traceroute`,
`mtr --report`, `ss -tin`/`ss -s`, `ip route get`, `ip neigh`, `ip -s link`, `arping`,
`ethtool -S`/`ethtool -a`, `tshark`, `dumpcap`, `.pcap`, `curl -v --resolve`, `openssl s_client`,
`nc -zv`, `socat`, `iperf3 -R -P -u`, `/proc/net/nf_conntrack`, `/proc/net/sockstat`,
`net.ipv4.ip_local_port_range`, `somaxconn`, `TIME_WAIT`, `bpftrace`, `pwru`, `hubble observe`,
`kubectl debug`, `nicolaka/netshoot`, `tcp_retries2`, "flow logs".

**Guiding principle** (inherited from `networking-standards`: *the network is default-deny and documented
as code; what is not in the SoT does not exist*): **diagnosis ends in a proven root
cause, not in "it fixed itself"**. Every step answers a falsifiable hypothesis written before
typing, changes **one** variable, and leaves saved evidence. A problem that disappears with no
explanation is not solved: it is waiting.

**Not applicable**: see `networking-standards` (**parent**: the **design** —topology, addressing,
VLAN, routing/BGP, correct MTU/MSS values, proxies, overlays, OOB plane—; **it says how the network
should be, you find out why today it is not**; the structural fix goes back to it),
`observability-standards` (**permanent telemetry and its alerts**: metrics, logs, traces,
dashboards, SLI/SLO, sampling, retention and the design of what is instrumented **before** there is a
problem — **all continuous monitoring is theirs; you are the reactive diagnosis once the alert
has fired**. The exact line: if the question is "what is measured and at what threshold do we alert?", it is theirs;
if it is "this is broken now, why?", it is yours. And the evidence you need and that does not exist is a
finding **for** them: every blind diagnosis ends in an instrumentation requirement),
`incident-management-standards` (**the process of the declared incident**: severity, Incident
Commander, channel, communication, mitigate-before-diagnosing, postmortem — **command and
communication are theirs; technical diagnosis inside the incident is yours**. When the IC asks to
mitigate now, you mitigate and **note down** what you sacrifice in evidence),
`firewall-policy-standards` (**the policy**: when the diagnosis concludes "a rule is missing" or
"there is a rule too many", the fix, its approval and its negative test are theirs; **proving
that the packet dies in the filter is yours**),
`dns-standards` (**the name service and its data**: zone, TTL, DNSSEC, legitimate resolver,
delegation; **you prove that resolution is the cause and who answers what**, they decide
which is the right answer), `vpn-standards` (**the tunnel**: design, keys, correct MTU and keepalive,
concentrator redundancy; **"the VPN connects but I cannot browse" is yours** —it is
PMTU and it is proven with a capture at both ends—, likewise "it drops after 5 minutes" and "it resolves
badly inside the tunnel"), `linux-administration-standards` (`resolvectl`, `systemd-resolved`,
`nsswitch.conf`, systemd units and resolution **from the host**; `dmesg` and boot),
`linux-storage-standards` (when "the network is slow" turns out to be I/O: `iostat`, `fio`),
`kubernetes-standards` (CNI, `NetworkPolicy`, `Service`/`Ingress`, service mesh: their **design**),
`container-runtime-security-standards` (container isolation and the eBPF agent's privileges —
a privileged debugging pod is a security decision, not a shortcut),
`detection-engineering-standards` (analytics over network telemetry; **a traffic capture
made to investigate a compromise, not a fault, belongs to them and to**
`incident-response-forensics-standards` —chain of custody and preservation—),
`sre-practice-standards` (SLO, error budget, managing the *toil* of repeated diagnosis),
`aws-standards`/`azure-standards`/`gcp-standards` (flow logs, Reachability Analyzer/Network Watcher
and equivalents: the provider's tool and its configuration),
`data-platform-standards` (latency that turns out to be the database engine's, not the network's),
`microservices-architecture-standards` (timeouts, retries and circuit breakers as the application's
**design**; here you only prove that the failure comes from there),
`appsec-standards` (a failure that turns out to be the application's), `onprem-standards` (umbrella),
`homelab-standards` (your own lab), `offensive-security-standards` (**scanning a network that is not
yours, or active sweeping without authorisation, is not diagnosis**), and the three design and
proactive-operations skills the cause **returns to once found**: if the fault
is explained by the campus design or by a BGP policy, the structural fix belongs to
`routing-switching-standards`; if encapsulation MTU, asymmetric ECMP or EVPN appears, it belongs to
`datacenter-fabric-standards`; and **if the answer to "what changed?" is a configuration
deployment, the rollback and the gate that should have prevented it belong to `network-automation-standards`**.
Here the work ends when the cause is proven; the permanent fix lives there.

They also exist and are boundaries: `ha-clustering-standards` (*split brain*, fencing and the cluster
network: **the expected behaviour of the cluster under partition is theirs; proving that there was a
network partition and why is yours**) and `podman-systemd-containers-standards` (rootless networks with
`netavark`/`pasta` and their resolution: their **configuration** is theirs, the diagnosis of the packet
lost between namespaces belongs here).

## 2. Default decisions / Toolchain

> Verify the latest version and maintenance status on the web before committing to anything (§8).
> Dates obtained from `api.github.com` and the project's site, not from summarised HTML pages.

| Question you are answering | Default tool | Alternative | Banned |
|---|---|---|---|
| What is configured on this machine? | `ip addr`/`ip link`/`ip route`/`ip neigh`/`ip -s link` (**iproute2**) | `nmcli`/`networkctl` depending on the manager | `ifconfig`, `route`, `arp`, `netstat` (**net-tools**: no release since 2001, unmaintained; they **hide** namespaces, routing policies, multiple tables and modern socket state) |
| Which route would **this** packet take? | `ip route get <dst> from <src>` | `ip rule show` for policy routing | Reading the main table and assuming |
| Which sockets and in which state? | `ss -tanp`, `ss -tin` (RTT, cwnd, retransmissions), `ss -s` | `/proc/net/sockstat` | `netstat -an` |
| Does the packet arrive and come back? | **`tshark`/`dumpcap` capturing at BOTH ends at the same time** | A capture at each intermediate hop if the path has several | Capturing at only one end and inferring |
| Analysing the capture? | **Wireshark 4.6.x** (GUI) to analyse; `tshark` to filter and automate | `capinfos`, `editcap`, `mergecap` | Eyeballing 2 GB of pcap instead of filtering |
| Where is it lost and how much? | `mtr --report --report-cycles 100 -w` (**v0.96**; repo with activity in Jun 2026) | `traceroute -T -p 443` when ICMP/UDP is filtered | `ping` as the only quality measurement |
| Is layer 1-2 healthy? | `ethtool <if>` (negotiation), `ethtool -S` (error/discard counters), `ethtool -a` (pause) | `ip -s link` for aggregate errors | Diagnosing layer 3 without having looked at interface errors |
| State of filtering and NAT? | `nft list ruleset` with `counter`; `/proc/net/nf_conntrack` and `nf_conntrack_count` vs `nf_conntrack_max` (**conntrack-tools 1.4.9**) | `nft monitor trace` to follow a packet through the chains | Assuming "the firewall is open" because somebody said so |
| Does the application accept? | `curl -v` with **`--resolve`** (isolates DNS from connectivity), `openssl s_client -connect -servername` | `nc -zv` for a raw port; `socat` for relays and protocol tests | `telnet host port` as a TLS test |
| How much bandwidth is there really? | **`iperf3 3.21`** (09 Apr 2026) with `-P` (parallel), `-R` (reverse direction) and long runs | `iperf3 -u -b` for UDP with a fixed rate, measuring loss and jitter | Measuring 10 s in one direction and calling it a *baseline* |
| Where does the packet die **inside** the kernel? | **`pwru` v1.0.12** (13 Jul 2026, kernel ≥5.3; `--output-skb` ≥5.9) | `bpftrace 0.26.1` (02 Jun 2026) and `bcc 0.37.0` tools (02 Jul 2026) for bespoke cases | Guessing between `nftables`, routing and the driver |
| And in Kubernetes? | `hubble observe --verdict DROPPED` (Cilium **1.20.0**, 29 Jul 2026); `kubectl debug --image=nicolaka/netshoot` with `--target` | `kubectl debug node/<n>` for the node's netns; Retina where the CNI is not Cilium | `kubectl exec` into a *distroless* container and giving up |
| And in the cloud? | The provider's **flow logs** + its reachability analyser | A capture on the instance if the provider does not offer a managed one | Concluding "it is the cloud" without looking at the flow logs |

**On eBPF (`pwru`, `bpftrace`, `bcc`, Hubble): recommended, but not as the first step.**
They are the answer to "the packet enters the machine and does not come out, and no classic tool tells me
where" — a real and frequent problem on hosts with containers, and where classic capture does not
reach because the drop happens between capture points. Requirements and cost to accept
beforehand: a modern kernel with **BTF** and `CONFIG_KPROBES`/`CONFIG_BPF`, high privileges on the host
(a security decision, see `container-runtime-security-standards`), and non-zero overhead in
production. **Criteria**: layer 1-2, `ss`, capture at both ends and firewall counters
first; eBPF when those four do not close the case.

## 3. The method

### 3.1 Before typing anything: four questions

1. **What changed?** — The cause is the last change until proven otherwise. The
   diagnosis **starts in change control**: deployments, firewall or routing changes,
   patching, certificate renewal, change of provider, firmware update, the expiry of
   something. If nobody knows what changed, that is the first finding (and a governance problem, not a
   network one).
2. **What exactly is "it does not work"?** — Reproduce the symptom precisely: which source, which
   destination, which port, which protocol, which client, at what time, with which literal error message.
   "The network is bad" is not a symptom; "from host A, `curl` to B:443 hangs after the
   TLS handshake, in 30% of attempts, since 09:14" is.
3. **What is the scope?** — One user or all of them? One destination or all of them? One protocol or all of them?
   One VLAN, one node, one availability zone? Scope **discards more hypotheses in 30
   seconds than an hour of captures**: a failure that affects a single client is not in the
   server, and one that affects every destination is not in the destination.
4. **Did it ever work?** — "It never worked" is a **configuration or design** problem;
   "it worked and stopped working" is a **change or resource exhaustion** problem. They are
   two different investigations and confusing them costs hours.

### 3.2 Bisection: divide the path, do not walk it

- **You do not walk the path hop by hop.** You **split it in half**: pick an intermediate point
  with visibility (a router, a load balancer, a node) and determine whether the problem is before or
  after. Repeat. With 8 hops, bisection is 3 tests; walking it linearly, 8 — and with more
  opportunities to get it wrong.
- **Bisection also applies to non-spatial dimensions**: two clients (one that fails,
  one that does not) → what differs?; two destinations; two protocols; two moments; IPv4 vs. IPv6. The cut
  is by *variable*, not just by *place*.
- **One variable at a time.** Changing two things and having it work is not a diagnosis: it is a
  coincidence you will have to deal with again. If pressure forces changing several at
  once to mitigate, it is **noted** and reverted one by one afterwards to identify which one it was.
- **A falsifiable hypothesis before typing**: write down "if the cause is X, then doing Y I will see Z;
  if I see W, X is ruled out". A test that cannot refute your hypothesis is not a test, it is
  a ceremony. This is what separates diagnosis from "firing off commands".
- **Confirmation bias is the main enemy**: as soon as you have a suspect, every
  test seems to confirm it. Antidote: define in advance **what result would make you abandon** that
  hypothesis, and look for it explicitly.

### 3.3 The canonical sequence

Four questions, in order. Each one has a binary answer and eliminates half the universe.

**1) Does the name resolve — and to the right thing?**
- Isolate DNS from the rest **from the first minute**: `curl -v --resolve host:443:<ip>` directly
  compares "does not resolve" against "does not connect". If it works with `--resolve`, the problem is
  resolution and not the network.
- Ask **each** resolver separately and compare them, and **compare that with what the process
  actually uses**: the system may have a local stub, a cache, a `search` that completes the name,
  a forgotten `/etc/hosts` or a library that does not even go through the OS resolver.
  Resolution "from the shell" and "from the application" **are not the same**.
- Negative caching and TTL explain the classic "it works for me and not for you" and "it took an hour to
  fix itself". Zone, TTL and resolver design, in `dns-standards`.

**2) Does the packet reach the destination?**
- Capture **at the destination**, filtering by source and port. If it does not appear, the packet dies on the
  way: firewall, route, NAT, VLAN, layer 1-2.
- Check at the source that it **leaves** and through which interface: `ip route get <dst> from <src>` answers
  the real question (it includes policy routing and the effective table), not the main table.
- If it leaves and does not arrive, bisect the path and check the counters of the filtering rules at each
  hop: a `counter` incrementing on the drop rule is a proof, not a suspicion.

**3) Does the response come back? — the forgotten half of the problem**
- **The response gets lost as much as the outbound, and almost nobody looks at it.** If at the destination you see the `SYN`
  and the `SYN/ACK` leaves, but the source does not receive it, the problem is the **return path** and everything
  you were looking at was irrelevant.
- Typical causes of asymmetric failure: the return takes a different path (multihoming, specific
  routes, partial VPN, VRF); a stateful firewall that only sees one direction and drops the other
  for lack of state —**an unmistakable symptom: it works for a while and then cuts off, or it fails
  intermittently and non-reproducibly**—; NAT in one direction and not the other; uRPF dropping because of an
  invalid reverse path.
- **Operational rule**: in every hard case, simultaneous capture at both ends **with synchronised
  clocks**, and compare. This solves 90% of what looks impossible: it tells you in which half
  of the path the packet disappears and with that the investigation is reduced to half the network. If
  the path also has an intermediary (proxy, load balancer, NAT), capture on both of its sides.
- Correcting asymmetry is a design (`networking-standards`) or policy
  (`firewall-policy-standards`) matter: it is **never** fixed by adding a broad `accept`.

**4) Does the application accept it?**
- The packet arrives, the `SYN/ACK` comes back, and the failure persists: check whether the process **listens** (`ss
  -tanp`), on which address (`0.0.0.0` vs `127.0.0.1` vs `::` — a service on loopback is
  unreachable from outside and looks like a firewall), and whether the accept queue is full
  (`ss -lt` shows `Send-Q` as the backlog and `Recv-Q` as pending: if it saturates, the kernel
  drops `SYN`s and the client sees *timeouts* with the server "alive").
- Failures that **look** like network ones and are the application's or its edge's: an immediate `RST` (nobody listens
  or the proxy rejects), a TLS handshake failing because of SNI, certificate, version or chain
  (`openssl s_client -servername`), redirects, authentication, or the application's own *timeouts*
  shorter than its retry.
- **`RST` vs. *timeout* is the trade's most informative distinction**: `RST` = something answered and
  rejected (live host, closed port, a proxy or firewall that **rejects**); silence = something dropped
  (a firewall that **drops**, a missing route, a downed host). They are not the same problem and they are not
  diagnosed the same way.

### 3.4 Which lie each tool tells

No tool lies out of malice: they all answer a narrower question than the one you think you
are asking.

- **`ping` / ICMP** — it measures *that the destination answers ICMP*, not that the service works. ICMP is usually
  **deprioritised** in the control plane of routers and switches, or filtered by policy. A
  `ping` with 200 ms and loss towards the network device may be perfectly normal while the
  data traffic runs impeccably; and a perfect `ping` says nothing about port 443. **Never use
  `ping` as the only quality measurement or as a proof of service.**
- **`traceroute`/`mtr`** — the trade's most widespread lie: **loss at intermediate hops
  means nothing**. Routers generate `TTL exceeded` responses in their CPU and rate-limit them;
  seeing 40% loss at hop 5 and 0% at the destination means **that router prioritises its
  work, not that there is a problem**. Only two things count: (a) loss at the **last hop** (the
  destination), and (b) loss that **persists** from one hop to the end. Besides, ECMP makes
  each probe take a different path (use fixed-flow mode if your tool supports it),
  the return path is invisible, and MPLS can hide hops entirely. When ICMP/UDP is
  filtered, `traceroute -T` over the application's real port is what reflects the path that
  matters.
- **`ss`** — it tells you the socket's **local** state. `ESTABLISHED` at one end does not imply the other
  is still there: a connection whose peer disappeared without a `FIN` keeps showing as established until a
  keepalive or a write discovers it. `ss -tin` does give gold: RTT, `cwnd`, retransmissions — which
  distinguish "the network is losing" from "the application is slow".
- **`tcpdump`/`tshark`** — they capture where you are and **after** the kernel has decided
  some things and **before** others: a packet dropped by the filter may or may not appear in the
  capture depending on the hook point, and offload (GRO/GSO/TSO/LRO) shows giant "packets" that
  do not exist on the wire (disable it if you are going to analyse sizes or MTU). With sampling or a badly
  written filter, your "it does not show up" may be yours, not the network's. And an unfiltered capture on a loaded
  link loses itself: use a capture filter (BPF) for what you want, and a display
  filter to analyse.
- **`ip route`** — it shows tables; **`ip route get`** shows the decision. With policy rules,
  VRF or several tables, reading the main one and assuming is a classic mistake.
- **`ip neigh`/ARP** — a `STALE` or `FAILED` entry tells you more than a `REACHABLE` one; and a correct entry
  with the **wrong MAC** (duplicate IP, unexpected proxy ARP) is a silent failure
  that no layer 3 test gives away. `arping` from the same segment reveals **duplicate IPs**
  (two answers, two MACs) in one second, which is what no other tool does.
- **`ethtool`** — the only one that sees layer 1-2: negotiation (duplex/speed; a badly negotiated
  *half duplex* shows up as "slow and intermittent" under load), CRC errors, drops due to
  lack of buffer, and per-queue counters. **Cumulative counters**: what matters is the
  **delta** during the failure, not the total since boot.
- **`iperf3`** — it measures what you ask it to, and by default that is not what you think. Classic mistakes: measuring
  10 s (all *slow start*), a single flow (limited by RTT and window, not by the link), only in
  one direction (`-R` measures the other, which may be the broken one), in UDP without setting the rate (`-b`) or setting it
  above capacity and calling your own saturation "network loss", with `iperf3` itself
  as the CPU bottleneck, or measuring against a shared public server.
  **`iperf3` measures one path between two points at one instant; it does not measure "the network".**
- **`curl -v`** — without `--resolve` it mixes DNS, connection, TLS and HTTP into a single result; with
  `--resolve` it separates the first. Its per-phase timings (`-w`) are a diagnosis in themselves: if the
  time goes on the `connect`, it is the network; on the `appconnect`, it is TLS; on the `starttransfer`, it is
  the application.
- **The application logs** — they say "connection timeout" for half a dozen mutually incompatible
  causes. Useful for the exact time and the scope; useless as a diagnosis.

### 3.5 The usual suspects and their characteristic symptom

A recognition table. The symptom is what makes you suspect; the proof is what demonstrates it.

| Suspect | Characteristic symptom | Proof that demonstrates it |
|---|---|---|
| **MTU / PMTU black hole** | **The connection opens and hangs while transferring**: SSH connects but `scp` stalls; the web page loads the HTML and not the images; "the VPN connects but I cannot browse". Typically after a tunnel or a change of encapsulation | `ping` with a large packet and the DF bit, increasing until you find the cut-off; a capture showing retransmissions of the same large segment with no ACK; absence of ICMP *fragmentation needed* coming back |
| **Filtered ICMP that breaks PMTUD** | Identical to the previous one, and **it never fixes itself** | The intermediary blocking ICMP type 3 code 4 (or ICMPv6 *packet-too-big*): it is seen by its absence in the capture on the side that should receive it |
| **DNS** | Intermittency that looks like the network's; "sometimes it takes exactly 5 seconds" (resolver timeout); it works by IP and not by name | `curl --resolve` versus a normal `curl`; querying each resolver separately |
| **Ephemeral port / NAT exhaustion** | Failures that increase with load, on the side that **initiates** many connections (proxy, NAT, API client) | Socket count against `net.ipv4.ip_local_port_range`; on the NAT, active sessions against its capacity |
| **Full conntrack table** | **Silent** drops under load, with a line in `dmesg` nobody looks at | `nf_conntrack_count` against `nf_conntrack_max`; `dmesg` with `table full` |
| **Different return path** | "It works for a while and then cuts off"; intermittent and irreproducible; it works in one direction | Simultaneous capture at both ends: you see the outbound and the response that does not arrive |
| **`TIME_WAIT` / exhausted backlog** | Connection *timeouts* with the server alive and CPU low; it worsens at peaks | `ss -s` (count by state), `ss -lt` with `Recv-Q` growing, the dropped-`SYN` counter |
| **Keepalive vs. an intermediary's *idle timeout*** | **"The session drops exactly after N minutes"** of inactivity. A firewall, NAT, load balancer or cloud with an idle timeout shorter than the client's keepalive | Reproduce with an idle session and a stopwatch; compare the intermediary's timeout with the TCP/application keepalive. It is fixed by lowering the keepalive, not by raising everybody's timeout |
| **Duplicate IP** | Unexplained intermittency that changes with the ARP cache lifetime; "sometimes it lands on a different server" | `arping` from the segment: two answers with different MACs |
| **Duplicate MAC / *MAC flapping*** | Massive loss on a segment; the switch logs learning the same MAC on different ports | Switch log; address table |
| **Layer 2 loop / broadcast storm** | The whole VLAN goes down or crawls; switch CPU at 100%; it starts right after plugging something in | Broadcast/multicast counters per port shooting up; STP with constant topology changes. It is an emergency: the port is isolated first |
| **Aged or incomplete ARP/ND** | A host unreachable from its own segment while everything else is fine | `ip neigh` in `FAILED`/`INCOMPLETE` state |
| **IPv6 enabled and failing while IPv4 works** | "It is slow" with delays of exact seconds at the start; it works with `-4`; it fails only on some clients | Compare `curl -4` and `curl -6`; route and ND on IPv6. Usual cause: `AAAA` published without real IPv6 connectivity, or an IPv6 firewall without parity with IPv4 |
| **Happy Eyeballs masking the failure** | The IPv6 failure is **almost** unnoticeable (the client retries over IPv4 after a short delay), so nobody fixes it and the initial latency is worse for everyone | A capture showing the abandoned IPv6 attempt. **RFC 8305** is the current specification; v3 is still a **draft** (§8) |
| **A proxy or TLS inspection in the middle** | An unexpected certificate, a forced TLS version, rewritten ALPN, HTTP/3 that does not work, mTLS that fails, a `Server` different from the expected one | `openssl s_client -servername` and compare the certificate issuer with the expected one |
| **Load balancer with one bad backend** | A **constant fraction** of requests fails (1 in N) | Repeat the test N+ times recording which backend each one goes to |
| **Expired certificate or incomplete chain** | It fails at an exact time, for everybody at once, with nobody having touched anything | `openssl s_client` showing the chain and the dates |
| **Layer 1** | Growing CRC errors, slow only under load, badly negotiated duplex, degraded optics | `ethtool -S` (delta during the failure), `ethtool` (negotiation), optical power on the device |
| **Saturation / bufferbloat** | Latency that shoots up **only when there is traffic**; the `ping` goes from 10 ms to 300 ms when a download starts | Latency under load versus at rest; link utilisation by percentiles |

### 3.6 Latency, loss and jitter: measuring them properly

- **Percentiles, never averages.** The average hides exactly what breaks the experience. Look at
  p50, p95, p99 and **the maximum**; and compare with the at-rest state, not with an absolute number. A p50 of 20 ms
  with a p99 of 2 s is a broken system that averages well.
- **Distinguish the three causes of "it is slow"**, because they have opposite fixes:
  - **Latency (RTT)**: it limits a TCP flow's throughput through the window. If the RTT is high, more
    bandwidth fixes nothing; more parallel flows or a larger window do.
  - **Loss**: it sinks TCP throughput disproportionately (1% loss can cost
    most of the performance on a high-RTT link). It is seen in retransmissions (`ss -tin`),
    not in the `ping`.
  - **Jitter**: irrelevant for a download, lethal for voice and video. It is measured with UDP at a fixed
    rate, not with TCP.
- **The measurement must reproduce the real case**: same source-destination pair, same protocol, same
  transfer size, same time of day. A test at rest does not reproduce a saturation problem,
  and a 10-second test does not reproduce a 20-minute problem.
- **If "it is slow" turns out to be I/O, CPU or the database, say so and close the case there**: the network is
  blamed by default, and proving that it is **not** the network is as valid a result as any
  other (with evidence, not with a denial).

### 3.7 Modern environments: containers, Kubernetes, clouds and overlays

- **The packet crosses several *network namespaces*.** Before capturing, decide **which one** you are
  capturing in: inside the container, on the host side of the `veth`, on the bridge, in the node's netns,
  on the physical interface, on the overlay interface. "It does not show up in the capture" almost always
  means "you captured in the wrong namespace".
- **Kubernetes: a checking order by the cluster's own layers** — does the `Service` name
  resolve? → does the `Service` have `Endpoints`/`EndpointSlice` (a `Service` with no endpoints from a badly
  written selector is the most common failure and does not look like a network one)? → is there a `NetworkPolicy` that
  denies it (the drop happens in the datapath, **before** reaching the pod)? → does the `readinessProbe`
  take the pod out of rotation? → do the CNI or `kube-proxy` have the rule? → does the node route?
  `hubble observe --verdict DROPPED` gives the verdict and the reason for the drop in one step; beware of
  **monitoring aggregation**, which can hide individual events from you.
- ***Distroless* containers with no tools**: `kubectl debug` with an ephemeral container
  (**GA since Kubernetes 1.25**) and a diagnostic image (`nicolaka/netshoot`), sharing the
  pod's namespace, and `kubectl debug node/<node>` for the node's netns. Two operational warnings:
  an ephemeral container **cannot be removed** until the pod is deleted and **has no resource
  limits**; and to extract a capture, **stream it over standard output** instead of writing the
  file inside (copying from an ephemeral container does not work).
- **Clouds**: the VPC/VNet **flow logs** are the first stop —they say whether the packet was
  accepted or rejected and by which rule— followed by the provider's reachability analyser. Their
  limits, which must be known: aggregation into windows (you do not see the packet, you see the flow), possible
  sampling, a delay of minutes, and no payload. The specific configuration, in
  `aws-standards`/`azure-standards`/`gcp-standards`.
- **Overlays and tunnels** (VXLAN, GENEVE, IPsec, WireGuard): capture **inside** the tunnel and
  **outside** —they are two different questions: "does the traffic enter the tunnel?" and "does the tunnel reach the other
  side?". And as soon as there is encapsulation, **MTU is the first suspect, always**.
- **Service mesh / sidecar**: the proxy may terminate TLS, rewrite headers, apply its
  own timeouts and retries and return errors that look like the application's. Its access logs
  are the source, not the capture.

## 4. Quality of the diagnosis (gates)

A diagnosis is accepted when it meets **all** of this. It is not bureaucracy: it is what prevents
the same incident from coming back in three weeks.

1. **Reproducibility**: there is an exact command or procedure that produces the symptom at will
   (or, if it is intermittent, a documented condition that triggers it and a measured rate). Without
   reproduction, the fix cannot be validated.
2. **Hypotheses recorded with their result**: what was tried, what was expected, what was seen and which
   hypothesis was ruled out. A record of exclusions is worth as much as the finding, and it prevents the
   next shift from repeating the same tests.
3. **Evidence saved, not described**: captures (`.pcap`) from **both** ends with a timestamp,
   complete command outputs, counters before/after, screenshots of graphs with their
   time range. "We saw packets being lost" is not evidence. Save the evidence **before**
   mitigating: mitigation destroys the state that proves it.
4. **Root cause proven, not inferred** — the central gate. "Proven" means you can
   explain the complete mechanism from the change or the condition to the symptom, **and** that you can
   reproduce the failure by activating the cause and make it disappear by deactivating it. Temporal correlation
   is not causation: "we rebooted and it was fixed" is a data point, not a conclusion.
5. **Fix validated by the test that was failing**, and additionally with the corresponding
   negative test (what was supposed to stay blocked is still blocked). And validated from the **real
   affected source**, not from the engineer's bastion.
6. **Absence of side effects verified**: what was touched did not break anything else. Temporary
   diagnostic changes (open rules, offload disabled, `tcpdump` running, raised timeouts,
   logs at debug) **are explicitly reverted** and the reversion is verified.
7. **Derived findings with an owner**: the configuration drift, the missing rule, the metric
   that did not exist, the runbook that was useless, the alert that did not fire. Each one is opened as work
   with an owner and a date — towards `observability-standards`, `firewall-policy-standards`,
   `networking-standards` or whoever is relevant.
8. **If the case is closed without a root cause** (it happens, and it is legitimate), it is closed **saying so**: what was
   ruled out, what instrumentation is missing to diagnose it next time, and what trigger is left
   armed to capture evidence when it comes back. That is a result; "it fixed itself" is not.

## 5. Security of the diagnosis

- **A traffic capture contains personal data, credentials and business content.** It is not
  an innocuous technical file. Treat it as classified data: controlled storage, restricted
  access, minimum retention and deletion when the case closes. If you are going to share it, anonymise it or
  trim to headers (`-s` to limit the capture) and remove the payload. Legal basis and
  minimisation, in `privacy-engineering-standards`.
- **Capturing in production is an action with impact**: it consumes CPU and disk and can fill a
  filesystem. Use a capture filter, a size limit and rotation, and give it a time limit
  from the start. A forgotten `tcpdump` on a server is a future incident.
- **Distinguish a fault from a compromise from the first minute.** If there is any sign of intrusion,
  the objective stops being "restore the service" and becomes "preserve the evidence": the procedure changes,
  do not reboot, do not delete, and escalate to
  `incident-response-forensics-standards` (order of volatility and chain of custody).
- **Port sweeping, scanning or injecting traffic into networks that are not yours —or without internal
  authorisation— is not diagnosis**: it is offensive activity and it is governed in
  `offensive-security-standards`. Inside your network, warn whoever is monitoring so that your test does not
  show up as an attack.
- **Privileges**: capturing requires `CAP_NET_RAW`/`CAP_NET_ADMIN` and eBPF requires more. Grant them
  **temporarily and by name**, not as a permanent configuration nor with a privileged container
  that stays there (`container-runtime-security-standards`). Withdraw them when the case closes.
- **Do not weaken controls to diagnose and then leave it like that**: opening a rule "to test" is the
  fastest route to a permanent `any/any` (`firewall-policy-standards`). If you open, you open with
  an automatic expiry.

## 6. Operability: preparing before it fails

- **Diagnosis is prepared, not improvised.** What must exist **before** the incident:
  an up-to-date inventory and SoT (`networking-standards`), a diagram of the traffic's real path,
  OOB access, telemetry with sufficient retention (`observability-standards`), flows, and **baselines**:
  normal RTT, normal throughput, normal error rate. **Without a baseline, "it is high" is an
  opinion.**
- **A synchronised clock on everything that logs or captures** (healthy NTP/chrony). Without it, correlating
  two captures or two logs is impossible, and that is precisely the method that solves the hard cases.
- **An available observation point**: SPAN/mirror, TAP, or at least a host with access to the segment and
  tools installed. If the first step of your diagnosis is "install `tcpdump` on the production
  server", you are already too late.
- **A minimum kit preinstalled or a diagnostic image ready**: iproute2, capture, `mtr`, `curl`,
  `nc`/`socat`, `ethtool`, `iperf3`, and a diagnostic container image for environments with no
  tools.
- **Runbooks by symptom, not by tool**: "it does not resolve", "it connects and hangs while transferring",
  "intermittent", "slow only under load", "it drops every N minutes", "1 in N fails", "it works
  from one host and not from another". Each one with the canonical sequence adapted and its escalation
  criterion.
- **A rescue window open when touching remote access, routes or the firewall** — an inherited and non-
  negotiable rule (`firewall-policy-standards`, `vpn-standards`): OOB console, a second path, or
  a timed rollback. Locking yourself out during a diagnosis is the most predictable and most
  avoidable incident there is.
- **When the diagnosis happens inside a declared incident**: command and communication belong
  to `incident-management-standards`. You give **hypotheses with a confidence level and an estimated time**,
  not premature certainties; and if the IC decides to mitigate before understanding, you mitigate — but **you capture
  the evidence first** and leave the pending diagnosis written down. Mitigating does not close the root cause.
- **Toil**: the same diagnosis repeated three times is an instrumentation or design failure, not
  bad luck. It becomes an alert, an automatic check or a structural fix
  (`sre-practice-standards`).

## 7. Sustainability and prohibitions

- **The postmortem feeds the method**: every hard case leaves either a new runbook, or a new
  metric, or a design change. If it leaves nothing, it will happen again.
- **Tool migration**: `net-tools` (`ifconfig`, `netstat`, `route`, `arp`) has been
  unmaintained for years and is absent by default in modern distributions; scripts and
  runbooks that still use it are migrated to **iproute2** with a date. It is not purism: it **hides** namespaces,
  policy routing and state that today determines the diagnosis.
- **Cadence**: review the version and CVEs of the capture and analysis tools (Wireshark/`tshark`,
  `libpcap`/`tcpdump`) along with the rest of the stack — **they are parsers that process hostile input by
  definition**, and 2026 brings a flood of LLM-assisted findings in that family. Analysing an
  untrusted capture with an unpatched Wireshark is exposing yourself.
- **Training with real cases**: keeping captures and timelines of solved cases as
  team training material is worth more than any course.

**FORBIDDEN**
- ❌ **Rebooting as the first step.** It destroys the state you need (sockets, conntrack,
  counters, ARP cache, in-memory logs) and turns the problem into something irreproducible. It is the last resort,
  and with the evidence already collected.
- ❌ Changing **several things at once** and declaring victory when it works.
- ❌ Touching production blind: diagnostic changes with no hypothesis, no record and no rollback
  plan.
- ❌ **Blaming the network without evidence** — and also absolving it without evidence. Both are the same
  failing.
- ❌ **Capturing at only one end** in a hard case, or capturing without clock synchronisation.
- ❌ Concluding from loss at **intermediate hops** in `traceroute`/`mtr`.
- ❌ Using `ping` as proof that a service works, or as the only quality measurement.
- ❌ `ifconfig`, `netstat`, `route`, `arp` (`net-tools`) in diagnosis or in new runbooks.
- ❌ Reading `ip route` and assuming, instead of asking with `ip route get`.
- ❌ Measuring with `iperf3` for 10 s, a single flow, a single direction, and calling it a *baseline*.
- ❌ Reporting latency averages instead of percentiles.
- ❌ Analysing packet sizes or MTU without disabling the interface's offload.
- ❌ Diagnosing layer 3 without having looked at layer 1-2 errors and negotiation.
- ❌ Closing the case with "it fixed itself", "it was a network thing" or "we rebooted and it works now".
- ❌ Leaving the diagnosis's temporary changes in place (open rules, captures running,
  offload disabled, logs at debug, elevated privileges, a privileged debugging pod).
- ❌ Opening a firewall rule "to test" without an automatic expiry.
- ❌ Storing captures with personal data or credentials outside controlled storage, or
  sharing them without trimming.
- ❌ Treating a possible compromise as a fault: destroying evidence in order to restore the service.
- ❌ Scanning or injecting traffic into other people's networks, or without internal authorisation, in the name of
  diagnosis.
- ❌ Changing routes, rules or remote access **over the very path you are touching** without a rescue
  window.
- ❌ Starting with eBPF (or with Wireshark) before having looked at the interface, sockets, routes and counters.
- ❌ Repeating the same manual diagnosis over and over without turning it into instrumentation.

## 8. Mandatory web verification

Before pinning any version, behaviour or limit, **look it up — do not recall it**.
**Methodology**: the versions and dates in this document come from `api.github.com/repos/…` and from
the project's site, **not** from the summary of an HTML releases page (which invents years).

Verified Aug 2026:

- **Capture and analysis**: `tcpdump` **4.99.6** and `libpcap` **1.10.6** (both 30 Dec 2025; libpcap
  1.10.6 fixes CVE-2025-11961 and CVE-2025-11964, out-of-bounds read and write in
  `pcap_ether_aton()`); work in progress towards tcpdump 5.0 and libpcap 1.11. **Wireshark** stable
  branch **4.6.x** (4.6.7 and 4.4.17 released in 2026, with multiple vulnerabilities fixed,
  attributed by the project to the rise in AI-assisted reports); minimum 18 months of support
  per release; **4.6 is the last one supporting Windows 10, RHEL 8 and Qt 5**.
- **Measurement**: **iperf3 3.21** (09 Apr 2026; previously 3.20 on 14 Nov 2025 and 3.19.1 on
  25 Jul 2025). **mtr**: latest tag **v0.96**, repository with activity in Jun 2026.
- **State**: **conntrack-tools 1.4.9** (packaged in Debian Feb 2026, succeeding the 1.4.8 series from
  Mar 2024).
- **net-tools versus iproute2**: `net-tools` **with no official release since 2001** and with no
  active maintenance; absent by default in Debian ≥9, RHEL/CentOS ≥7 (with `ifconfig` out by
  default in Ubuntu 18.04+, CentOS 8+, Fedora 22+ and Arch). **It remains discouraged** and the reason is
  functional as well as hygienic: it does not expose the modern kernel state. Mapping: `ifconfig` →
  `ip addr`/`ip link`, `route` → `ip route`, `arp` → `ip neigh`, `netstat` → `ss`.
- **eBPF for diagnosis**: **`pwru` v1.0.12** (13 Jul 2026; kernel ≥5.3, `--output-skb` ≥5.9,
  `--backend=kprobe-multi` ≥5.18; requires `CONFIG_DEBUG_INFO_BTF`, `CONFIG_KPROBES`,
  `CONFIG_PERF_EVENTS`, `CONFIG_BPF`), **`bpftrace` 0.26.1** (02 Jun 2026), **`bcc` 0.37.0**
  (02 Jul 2026), **Cilium 1.20.0** (29 Jul 2026) with Hubble. **Microsoft Retina reached 1.0/GA** and
  allows Hubble without requiring Cilium as the CNI, with known limitations (IP→pod mapping in user
  space, no L7 visibility). Conclusion: **mature and recommendable, but as a second line**, not
  as a first step.
- **Kubernetes**: ephemeral containers and `kubectl debug` **GA since 1.25**; `nicolaka/netshoot`
  as the usual image; the ephemeral container **cannot be removed** until the pod is deleted and **has no
  resource limits**; `kubectl cp` **does not work** with ephemeral containers (stream the
  capture over standard output).
- **Happy Eyeballs**: **RFC 8305 (Happy Eyeballs v2, Dec 2017) is still the current
  specification**. `draft-ietf-happy-happyeyeballs-v3` is an **Internet-Draft** (revision -03, Mar 2026)
  and it **updates** the algorithm description in RFC 8305, it does **not obsolete** it yet. Do not cite it
  as an RFC.

**Declared gaps — do NOT fill in from memory, verify before using**:
1. **Current `ethtool` version**: **not verified**. Secondary sources give 6.15 (Jun 2025) and
   mention 6.20 in package repositories; the kernel.org index did not return the recent entries
   in this query. Check at `kernel.org/pub/software/network/ethtool/` or in your
   distro before pinning a minimum version.
2. **The exact version number of Wireshark 4.6.7 and its date**, and the status of the 4.7.x development
   branch: obtained from secondary sources, **with no confirmed date**. Cross-check at
   `wireshark.org/news`.
3. **Recent Wireshark/`tshark` CVEs** (identifiers and severity): only the existence of a batch fixed
   in 2026 is established; **they have not been enumerated or verified**. Look them up before pinning
   a minimum version in a runbook.
4. **Distro-packaged versions** of `iproute2`, `ethtool`, `conntrack-tools`, `tcpdump` and
   `mtr` in RHEL 10, Fedora, Debian 13 and Ubuntu LTS: **not verified**. What is operational is the
   package's version, not upstream's.
5. **Release date of `mtr` v0.96**: only the tag in the repository is established (with no published
   *releases*) plus commit activity in Jun 2026; **publication date not confirmed**.
6. **Maintenance status of `iperf2`** (a separate project from iperf3) and of `socat`, `nmap` and
   `ncat`: **not verified** in this pass.
7. **Exact capabilities, delay and sampling of the flow logs and reachability analysers**
   of AWS, Azure and GCP: described as general criteria, **not verified** against each provider's
   current documentation. Cross-check with `aws-standards`/`azure-standards`/`gcp-standards`.
8. **Details of Microsoft Retina 1.0** (specific version, GA date, CNI compatibility
   matrix): taken from a corporate blog, **unverified** against the repository or its
   releases.

If the web contradicts this document, **the web wins** — flag the discrepancy.
