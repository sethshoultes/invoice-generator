/**
 * Main App component
 * This is a placeholder - full implementation will be done in Phase 5
 */

function App() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Invoice Digitization Service
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Phase 1: Project Setup Complete
        </p>
        <div className="bg-white p-8 rounded-lg shadow-md max-w-md mx-auto">
          <h2 className="text-2xl font-semibold text-gray-800 mb-4">
            Next Steps
          </h2>
          <ul className="text-left text-gray-700 space-y-2">
            <li>✅ Firebase CLI installed</li>
            <li>✅ Project structure created</li>
            <li>✅ TypeScript configured</li>
            <li>✅ ESLint + Prettier set up</li>
            <li>⏳ Initialize Firebase project</li>
            <li>⏳ Deploy hello-world function</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default App
