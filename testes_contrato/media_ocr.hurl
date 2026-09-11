# T-041 — POST /media/ocr: caminho feliz, sem token, imagem grande demais
# -> 413, imagem ilegível -> OCR_NO_TEXT. Critério de conclusão explícito
# do T-041.
#
# Precisa de 3 variáveis extras (fixtures da T-020, geradas via shell — a
# imagem em si nunca é versionada em base64 dentro deste arquivo). Ver
# tests/hurl/README.md para o comando completo.

# sem token -> AUTH_EXPIRED
POST {{base_url}}/media-ocr
{
  "image": "{{image_base64}}",
  "mimeType": "image/png"
}
HTTP 401
[Asserts]
jsonpath "$.code" == "AUTH_EXPIRED"

POST {{base_url}}/auth-login
{
  "email": "cenario-cheio@cerne.test",
  "password": "{{test_account_password}}"
}
HTTP 200
[Captures]
access_token: jsonpath "$.data.session.accessToken"

# imagem acima de OCR_MAX_BYTES decodificada -> 413 PAYLOAD_TOO_LARGE
POST {{base_url}}/media-ocr
Authorization: Bearer {{access_token}}
{
  "image": "{{image_base64_oversized}}",
  "mimeType": "image/png"
}
HTTP 413
[Asserts]
jsonpath "$.code" == "PAYLOAD_TOO_LARGE"

# imagem ilegível (página em branco, T-020) -> OCR_NO_TEXT
POST {{base_url}}/media-ocr
Authorization: Bearer {{access_token}}
{
  "image": "{{image_base64_illegible}}",
  "mimeType": "image/png"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "OCR_NO_TEXT"

# caminho feliz: caderno manuscrito legível (T-020) -> texto + confidence
POST {{base_url}}/media-ocr
Authorization: Bearer {{access_token}}
{
  "image": "{{image_base64}}",
  "mimeType": "image/png"
}
HTTP 200
[Asserts]
jsonpath "$.data.text" exists
jsonpath "$.data.text" != ""
jsonpath "$.data.confidence" matches "^(high|low)$"

# corpo inválido (mimeType fora do enum) -> VALIDATION_ERROR
POST {{base_url}}/media-ocr
Authorization: Bearer {{access_token}}
{
  "image": "{{image_base64}}",
  "mimeType": "image/gif"
}
HTTP 400
[Asserts]
jsonpath "$.code" == "VALIDATION_ERROR"
