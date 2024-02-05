import logo from "./logo.svg";
import "./App.css";

function App() {
  const version = process.env.REACT_APP_VERSION || "N/A";

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>React Demo CI App</p>
        <p>Version: {version}</p>
      </header>
    </div>
  );
}

export default App;
