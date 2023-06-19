import 'package:able/able.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'counter/counter_cubit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(counter: 0),
      child: Builder(
        builder: (context) {
          final counterF = context.select((CounterCubit c) => c.state.counterF);
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'You have pushed the button this many times:',
                  ),
                  widgetForFetchable(
                    context: context,
                    fetchable: counterF,
                    buildSuccess: (context, counter) {
                      return Text(
                        '$counter',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                    buildError: (context, error) {
                      return Text(
                        '$error',
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: Builder(builder: (context) {
              return FloatingActionButton(
                onPressed: () {
                  context.read<CounterCubit>().increment();
                },
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              );
            }),
          );
        },
      ),
    );
  }
}
