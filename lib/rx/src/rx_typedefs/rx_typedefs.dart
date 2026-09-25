/// A callable condition that returns `true` or `false`.
typedef Condition = bool Function();

/// A callback function that accepts data of type `T` and returns nothing.
typedef OnData<T> = void Function(T data);

/// A callback function that accepts no arguments and returns nothing.
typedef Callback = void Function();
