const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const BLACKBOX_TOKEN = process.env.BLACKBOX_TOKEN;

// --- BlackBox AI Fallback Function ---
async function fallbackToBlackBox(originalRequestData) {
    if (!BLACKBOX_TOKEN) {
        throw new Error('BlackBox token (BLACKBOX_TOKEN) is not configured.');
    }

    // The request format is the same as OpenAI's, so we can just forward it.
    const response = await axios.post(
        'https://api.blackbox.ai/chat/completions',
        originalRequestData,
        {
            headers: {
                'Authorization': `Bearer ${BLACKBOX_TOKEN}`,
                'Content-Type': 'application/json',
            }
        }
    );
    
    // The response format is also OpenAI-compatible, so we can return it directly.
    return response.data;
}

app.post('/gpt4', async (req, res) => {
    try {
        // --- Primary OpenAI Attempt ---
        if (!OPENAI_API_KEY || OPENAI_API_KEY === 'YOUR_OPENAI_API_KEY_HERE') {
            throw new Error('OpenAI API key is not configured or is a placeholder.');
        }

        const response = await axios.post(
            'https://api.openai.com/v1/chat/completions',
            req.body, // Forward the whole body
            {
                headers: {
                    'Authorization': `Bearer ${OPENAI_API_KEY}`,
                    'Content-Type': 'application/json',
                }
            }
        );
        res.json(response.data);
    } catch (err) {
        // --- Fallback Logic ---
        console.warn('OpenAI API failed. Attempting fallback to BlackBox AI...');
        console.error('OpenAI Error:', err.response?.data || err.message);

        try {
            const fallbackResponse = await fallbackToBlackBox(req.body);
            res.json(fallbackResponse);
        } catch (fallbackErr) {
            console.error('BlackBox AI fallback also failed:', fallbackErr.response?.data || fallbackErr.message);
            res.status(500).json({
                error: 'Both OpenAI and the BlackBox AI fallback failed.',
                openai_error: err.response?.data || err.message,
                fallback_error: fallbackErr.response?.data || fallbackErr.message
            });
        }
    }
});

app.get('/', (req, res) => {
    res.send('GPT Proxy with BlackBox Fallback is up and running!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server started on port ${PORT}`));
