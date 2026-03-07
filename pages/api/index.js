import { useEffect, useState } from 'react';

export default function Home() {
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    const interval = setInterval(async () => {
      try {
        const res = await fetch('/api/update');
        const data = await res.json();
        setMessages(data.messages);
      } catch (e) {
        console.log('Error fetch:', e);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h2>Live Telegram Messages</h2>
      <div
        style={{
          border: '1px solid #ccc',
          padding: '10px',
          height: '300px',
          overflowY: 'scroll'
        }}
      >
        {messages.map((msg, idx) => (
          <div key={idx} style={{ margin: '5px 0', padding: '5px', background: '#f0f0f0', borderRadius: '5px' }}>
            {msg.text}
          </div>
        ))}
      </div>
    </div>
  );
    }
