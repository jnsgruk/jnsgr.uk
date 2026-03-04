# {{ .Title }}

{{ .RawContent }}
{{ range .Pages }}
{{- $summary := "" }}{{ with .Params.summary }}{{ $summary = replaceRE `\s*\n\s*` " " (strings.TrimRight "\n" .) }}{{ end -}}
- [{{ .Title }}]({{ .Permalink }}){{ with $summary }}: {{ . }}{{ end }}
{{ end }}
