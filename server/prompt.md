# AI contract

Input: `{ "idea": string, "knownFields": { "title": string, "topic": string, "context": string, "need": string, "users": string, "data": string, "constraints": string, "outcome": string, "success": string, "contact": string, "format": string } }`.

Output: `{ "questions": [string, string, string, ...], "questionFields": [fieldKey, fieldKey, fieldKey, ...], "draft": { ...same fields... } }`. `questionFields[i]` is the card field filled from answer `questions[i]`.

The model must ask at least three specific questions about missing information. It may copy only verbatim facts explicitly stated in the input into draft fields. Unknown fields must be empty strings. The server validates the JSON, allowed field keys, and verifies draft values are literal substrings of the input. It falls back to labelled template questions when the model is unavailable or invalid. The model never scores a task or chooses a team.
