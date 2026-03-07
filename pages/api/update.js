let messages = [];

export default function handler(req, res) {
  if (req.method === 'POST') {
    const { message } = req.body;
    messages.push({
      text: message,
      timestamp: new Date().toISOString()
    });
    if (messages.length > 100) messages.shift();
    res.status(200).json({ status: 'ok' });
  } else if (req.method === 'GET') {
    res.status(200).json({ messages });
  }
}
