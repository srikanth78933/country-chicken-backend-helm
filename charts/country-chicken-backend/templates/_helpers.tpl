{{- define "app.name" -}}
country-chicken-backend
{{- end }}

{{- define "app.labels" -}}
app: country-chicken-backend
release: {{ .Release.Name }}
{{- end }}