# Master Plan: Silencing the Council's Inner Monologue

The High Council (AI) is currently sharing its internal thoughts (`<think>` blocks) which clutter the commentary and hit the character limit before the actual wisdom is shared. We need to strip these thoughts in the backend.

### 1. Update Backend Logic
- **File**: `backend/main.py`
- **Action**: Use regular expressions to remove any content between `<think>` and `</think>` tags.
- **Goal**: Ensure only the final, polished commentary is sent to the Flutter app.

### 2. Implementation Steps
- Import the `re` module in `backend/main.py`.
- Apply a regex substitution to `response.choices[0].message.content`.
- Strip leading/trailing whitespace after cleaning.
- Ensure the character limit (150) is applied *after* cleaning.

Awaiting your approval to begin coding.
