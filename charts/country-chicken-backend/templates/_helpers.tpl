{{- define "app.name" -}}
country-chicken-backend
{{- end }}

{{- define "app.labels" -}}
app: {{ include "app.name" . }}
release: {{ .Release.Name }}
{{- end }}