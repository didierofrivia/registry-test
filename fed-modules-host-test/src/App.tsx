import React from "react"
import {BrowserRouter as Router, Route, Switch} from 'react-router-dom'
// @ts-ignore
const FederatedArtifactsPage = React.lazy(() => import("registry/FederatedArtifactsPage"))

const config = {
    artifacts: {
        url: 'http://localhost:8080/apis/registry/'
    }
}

const history = Object.assign({}, window.history, {location: window.location})

const App = () => {
    return (
        <Router basename="/">
            <React.Suspense fallback={"loading..."}>
                <FederatedArtifactsPage config={config} history={history} />
            </React.Suspense>
        </Router>
    )
}

export default App