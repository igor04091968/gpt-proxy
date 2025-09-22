const express = require('express');
const axios = require('axios');
const app = express();
app.use(express.json());

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const HF_TOKEN = process.env.HF_TOKEN; // New environment variable

// --- Hugging Face Fallback Function ---
async function fallbackToHuggingFace(messages) {
    if (!HF_TOKEN) {
        throw new Error('Hugging Face token (HF_TOKEN) is not configured.');
    }

    // 1. Request Adapter: Convert OpenAI messages to a simple string prompt
    // We'll just take the last user message for simplicity.
    const lastUserMessage = messages.filter(m => m.role === 'user').pop();
    if (!lastUserMessage) {
        throw new Error('No user message found to send to fallback model.');
    }
    const prompt = lastUserMessage.content;

    const HF_API_URL = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2';

    const response = await axios.post(
        HF_API_URL,
        { inputs: prompt, options: { wait_for_model: true } }, // Added wait_for_model
        {
            headers: { 'Authorization': `Bearer ${HF_TOKEN}` }
        }
    );

    // 2. Response Adapter: Convert Hugging Face response to OpenAI format
    const generatedText = response.data[0]?.generated_text || 'Fallback model did not return text.';
    // The model often returns the input prompt as part of the generated_text, so we can try to remove it.
    const cleanText = generatedText.replace(prompt, '').trim();


    return {
        choices: [{
            message: {
                role: 'assistant',
                content: cleanText
            }
        }]
    };
}


app.post('/gpt4', async (req, res) => {
    try {
        // --- Primary OpenAI Attempt ---
        if (!OPENAI_API_KEY) throw new Error('OpenAI API key is not configured.');

        const { messages, model = 'gpt-3.5-turbo' } = req.body;
        const response = await axios.post(
            'https://api.openai.com/v1/chat/completions',
            { model, messages },
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
        console.warn('OpenAI API failed. Attempting fallback to Hugging Face...');
        console.error('OpenAI Error:', err.response?.data || err.message);

        try {
            const fallbackResponse = await fallbackToHuggingFace(req.body.messages);
            res.json(fallbackResponse);
        } catch (fallbackErr) {
            console.error('Hugging Face fallback also failed:', fallbackErr.response?.data || fallbackErr.message);
            res.status(500).json({
                error: 'Both OpenAI and the fallback API failed.',
                openai_error: err.response?.data || err.message,
                fallback_error: fallbackErr.response?.data || fallbackErr.message
            });
        }
    }
});

app.get('/', (req, res) => {
    res.send('GPT-4 Proxy is up and running with Hugging Face fallback!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server started on port ${PORT}`));
