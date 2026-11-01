{{- define "garage.rpcSecret" -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace "garage-config" -}}
{{- if and $secret $secret.data $secret.data.GARAGE_RPC_SECRET -}}
{{- $secret.data.GARAGE_RPC_SECRET | b64dec -}}
{{- else -}}
{{- randAlphaNum 32 | sha256sum -}}
{{- end -}}
{{- end -}}