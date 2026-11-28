/* The worker count of the status bar: the main isolate plus every
   background isolate the app spawned. Today the decoding of the heavy
   layers of the base runs there, so the bar shows a second worker
   while a map loads its geometry.
   SPDX-License-Identifier: MIT. */

class AppWorkers {
  static int spawned = 0;
}
