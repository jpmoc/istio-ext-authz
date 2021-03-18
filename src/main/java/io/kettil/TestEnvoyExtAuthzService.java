package io.kettil;

import com.google.rpc.Status;
import io.envoyproxy.envoy.service.auth.v3.AuthorizationGrpc.AuthorizationImplBase;
import io.envoyproxy.envoy.service.auth.v3.CheckRequest;
import io.envoyproxy.envoy.service.auth.v3.CheckResponse;
import io.envoyproxy.envoy.service.auth.v3.OkHttpResponse;
import io.grpc.Server;
import io.grpc.ServerBuilder;
import io.grpc.stub.StreamObserver;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.Closeable;
import java.io.IOException;
import java.util.Map;

@Slf4j
@Service
public class TestEnvoyExtAuthzService implements Closeable {
    private static final Integer GRANTED = 0;
    private static final Integer DENIED = 7;

    private final int gRpcPort;
    private Server server;

    public TestEnvoyExtAuthzService(@Value("${grpc.port}") int gRpcPort) {
        this.gRpcPort = gRpcPort;
    }

    @PostConstruct
    public void start() throws IOException {
        server = ServerBuilder.forPort(gRpcPort)
            .addService(newCheckRequestHandler())
            .build();

        server.start();

        log.info("gRPC listen port: {}", server.getPort());
    }

    @Override
    public void close() {
        if (server != null)
            server.shutdown();
    }

    private io.grpc.BindableService newCheckRequestHandler() {
        return new AuthorizationImplBase() {
            @SneakyThrows
            @Override
            public void check(CheckRequest request, StreamObserver<CheckResponse> responseObserver) {
                log.info("v3.CheckRequest: {}", request);

                int code = DENIED;
                String method = request.getAttributes().getRequest().getHttp().getMethod();
                String path = request.getAttributes().getRequest().getHttp().getPath();

                if (path.equals("/deny")) {
                    log.info("Path is /deny.");
                } else {
                    log.info("Path is NOT /deny.");
                    String objectNamespace = request.getAttributes().getContextExtensionsOrThrow("namespace_object");
                    String serviceNamespace = request.getAttributes().getContextExtensionsOrThrow("namespace_service");
                    String servicePath = request.getAttributes().getContextExtensionsOrThrow("service_path");
                    String relation = request.getAttributes().getContextExtensionsOrThrow("relation");
                    String objectIdPtr = request.getAttributes().getContextExtensionsMap().get("objectid_ptr");

                    String authzResult = request.getAttributes().getContextExtensionsMap().get("authz_result");

                    Map<String, String> headers = request.getAttributes().getRequest().getHttp().getHeadersMap();
                    String authorization = headers.get("authorization");


                

                    switch (authzResult) {
                        case "allow":
                            code = GRANTED;
                            break;

                        case "deny":
                            code = DENIED;
                            break;
                    }
                }

                switch (path) {
                    case "/allow":
                        code = GRANTED;
                        break;

                    case "/deny":
                        code = DENIED;
                        break;
                }

                log.info("v3.CheckRequest result: {}", code == GRANTED ? "GRANTED" : "DENIED");

                responseObserver.onNext(CheckResponse.newBuilder()
                    .setStatus(Status.newBuilder().setCode(code).build())
                    .setOkResponse(OkHttpResponse.newBuilder().build())
                    .build());

                responseObserver.onCompleted();
            }
        };
    }
}
