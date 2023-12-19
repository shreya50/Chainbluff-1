import React, { useState } from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { useEffect } from "react";
import Login from "./components/login/Login";
import Game from "./components/game/Game";
import ProtectedRoute from "./components/protectedRoute";
import GameLanding from "./components/home/GameLanding";
import GameTable from "./components/table/GameTable";

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(
    sessionStorage.getItem("isAuthenticated") === "true"
  );

  useEffect(() => {
    sessionStorage.setItem("isAuthenticated", isAuthenticated.toString());
  }, [isAuthenticated]);

  return (
    <Router>
      <div className="App">
        <Routes>
          <Route
            path="/"
            element={<Login setIsAuthenticated={setIsAuthenticated} />}
          />
          <Route
            path="/game-table"
            element={
              <ProtectedRoute
                isAuthenticated={isAuthenticated}
                authenticationPath="/"
              >
                <GameLanding />
                {/* <GameTable />  */}
              </ProtectedRoute>
            }
          />
          <Route
            path="/table/:gameId"
            element={
              <ProtectedRoute
                isAuthenticated={isAuthenticated}
                authenticationPath="/"
              >
                {/* <Game /> */}
                <GameTable /> 
              </ProtectedRoute>
            }
          />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
