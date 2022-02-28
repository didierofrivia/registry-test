import React, {Suspense} from "react"
const FederatedArtifactsPage = React.lazy(() => import("registry/FederatedArtifactsPage"))

const config = {
    artifacts: {
        url: 'http://localhost:8080/apis/registry/'
    }
}

const history = Object.assign({}, window.history, {location: window.location})

const App = () => {
    return (
        <div>
            <h1 >OH HAI APICURIO!</h1>
            <Suspense fallback={"loading..."}>
                <FederatedArtifactsPage config={config} history={history} />
            </Suspense>
        </div>
    )
}

export default App