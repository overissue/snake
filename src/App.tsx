import React, {useEffect, useState} from 'react';
import './App.css';

function App() {
  const [backendMessage, setBackendMessage] = useState<string>('');

  useEffect(()=>{
    fetch('http://localhost:3001')
    .then((response)=> response.text())
    .then((data)=> setBackendMessage(data))
    .catch((error)=> console.error('Error fetching data:', error));
  }, []);

  return (
    <div className="App">
      <header className="App-header">
        <h1>{backendMessage}</h1>
      </header>
    </div>
  );
}

export default App;
