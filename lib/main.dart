// Flutter Packages
import 'package:flutter/material.dart';

// Plugins
import 'package:graphql_flutter/graphql_flutter.dart';

// firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Views
import 'view/welcome.dart';
import 'view/login.dart';
import 'view/control_panel.dart';
import 'view/register.dart';

Future<void> main() async {
  await initHiveForFlutter();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final HttpLink httpLink = HttpLink(
    'http://localhost:3000/graphql',
  );

  final WebSocketLink websocketLink = WebSocketLink(
    'ws://localhost:3000/graphql',
    config: const SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: Duration(seconds: 30),
    ),
    subProtocol: GraphQLProtocol.graphqlTransportWs,
  );

  @override
  Widget build(BuildContext context) {
    final Link link = Link.split(
        (request) => request.isSubscription, websocketLink, httpLink);

    final ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: HiveStore()),
        defaultPolicies: DefaultPolicies(
          query: Policies(
            fetch: FetchPolicy.noCache,
          ),
          mutate: Policies(
            fetch: FetchPolicy.noCache,
          ),
          subscribe: Policies(
            fetch: FetchPolicy.noCache,
          ),
        ),
      ),
    );

    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'StreamWave',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        //home: const Home(),
        home: const Welcome(),
        routes: {
          '/welcome': (context) => const Welcome(),
          '/login': (context) => const Login(),
          '/register': (context) => const Register(),
          '/control_panel': (context) => const ControlPanel(),
        },
      ),
    );
  }
}
