#!/usr/bin/env bash
# スタック起動後の疎通確認。OTLP/HTTP にダミーのメトリクスとログを投げ、
# Prometheus と Loki に到達したことを確認する。
set -euo pipefail

OTLP="${OTLP_HTTP_ENDPOINT:-http://127.0.0.1:4318}"
NETWORK="${NETWORK:-harness-otel}"

# Prometheus / Loki はホストに公開していないので、同じネットワークに使い捨てコンテナを置いて叩く
inside() { docker run --rm --network "${NETWORK}" busybox:1.37 wget -qO- "$1"; }
now_ns=$(( $(date +%s) * 1000000000 ))

echo "1/4 metrics -> ${OTLP}/v1/metrics"
curl -sf -X POST "${OTLP}/v1/metrics" -H 'Content-Type: application/json' -d @- <<JSON
{"resourceMetrics":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"smoke-test"}}]},
 "scopeMetrics":[{"metrics":[{"name":"smoke.count","sum":{"aggregationTemporality":2,"isMonotonic":true,
 "dataPoints":[{"asInt":"1","timeUnixNano":"${now_ns}"}]}}]}]}]}
JSON

echo "2/4 logs -> ${OTLP}/v1/logs"
curl -sf -X POST "${OTLP}/v1/logs" -H 'Content-Type: application/json' -d @- <<JSON
{"resourceLogs":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"smoke-test"}}]},
 "scopeLogs":[{"logRecords":[{"timeUnixNano":"${now_ns}","body":{"stringValue":"smoke"},
 "attributes":[{"key":"event.name","value":{"stringValue":"smoke.event"}},{"key":"prompt","value":{"stringValue":"MUST-BE-SCRUBBED"}}]}]}]}]}
JSON

echo "3/4 Prometheus に smoke_count が現れるのを待つ（最長 90 秒）"
for _ in $(seq 1 18); do
  if inside "http://${NETWORK}-prometheus:9090/api/v1/query?query=smoke_count_total" | grep -q '"smoke-test"'; then
    echo "  ok"; break
  fi
  sleep 5
done

echo "4/4 Loki に届き、prompt 属性が落とされていることを確認"
sleep 3
start=$(( now_ns - 60000000000 ))
res=$(inside "http://${NETWORK}-loki:3100/loki/api/v1/query_range?query=%7Bservice_name%3D%22smoke-test%22%7D&start=${start}")
echo "${res}" | grep -q '"smoke"' && echo "  到達 ok"
if echo "${res}" | grep -q 'MUST-BE-SCRUBBED'; then
  echo "  NG: prompt 属性が残っている。attributes/scrub を確認"; exit 1
fi
echo "  scrub ok"
