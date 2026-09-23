# AI contract

Input: `{ "idea": string, "knownFields": { "title": string, "context": string, "need": string, "users": string, "data": string, "constraints": string, "outcome": string, "success": string, "contact": string, "format": string } }`.

Output: `{ "questions": [string, string, string, ...], "draft": { ...same fields... } }`.

The model must ask at least three specific questions about missing information. It may copy only facts explicitly stated in the input into draft fields. Unknown fields must be empty strings. The server validates the result and falls back to labelled template questions when the model is unavailable or invalid. The model never scores a task or chooses a team.
