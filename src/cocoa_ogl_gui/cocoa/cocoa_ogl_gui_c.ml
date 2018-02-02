(** Copyright (C) 2018,  Gavin J Stark.  All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @file          cocoa_ogl_gui_c.ml
 * @brief         Convert C stubs for Cocoa to suitable OCAML bindings
 *
 *)

(*a NSApplication module *)
module NSApplication = struct
  (*t t_ns_app - opaque structure for the C 'NSApplication' wrapper *)
  type t_ns_app

  (*t t_ns_window - opaque structure for the C 'NSWindow' wrapper *)
  type t_ns_window

  (*t t_reshape_draw_reason - enumeration for reason codes for reshape_draw *)
  type t_reshape_draw_reason =
    | Resize
    | Draw

  (*t t_ns_app_* callback types *)
  type 'a t_ns_app_create       = ('a -> unit)
  type ('a, 'b) t_ns_app_reshape      = ('a -> 'b -> t_reshape_draw_reason -> int -> int -> unit)
  type ('a, 'b) t_ns_app_handle_key   = ('a -> 'b -> unit)
  type ('a, 'b) t_ns_app_handle_mouse = ('a -> 'b -> unit)
  type 'a t_ns_app_destroy      = ('a -> unit)

  (*f external C stub function declarations *)
  external _NSApplication :     'a -> t_ns_app = "cocoa_ns_application_ns_app"
  external _NSApplication_set_callback_create       :  t_ns_app -> 'a t_ns_app_create option       -> unit     = "cocoa_ns_application_set_callback_create"
  external _NSApplication_set_callback_reshape_draw :  t_ns_app -> ('a, 'b) t_ns_app_reshape option      -> unit     = "cocoa_ns_application_set_callback_reshape_draw"
  external _NSApplication_set_callback_handle_key   :  t_ns_app -> ('a, 'b) t_ns_app_handle_key option   -> unit     = "cocoa_ns_application_set_callback_handle_key"
  external _NSApplication_set_callback_handle_mouse :  t_ns_app -> ('a, 'b) t_ns_app_handle_mouse option -> unit     = "cocoa_ns_application_set_callback_handle_mouse"
  external _NSApplication_set_callback_destroy      :  t_ns_app -> 'a t_ns_app_destroy option      -> unit     = "cocoa_ns_application_set_callback_destroy"
  external _NSApplication_run:  t_ns_app  -> unit     = "cocoa_ns_application_run"
  external _NSWindow_create:    t_ns_app -> 'a -> (float * float * float * float) -> t_ns_window = "cocoa_ns_application_create_window"
  external _NSWindow_debug:     t_ns_window -> unit = "cocoa_ns_window_debug"

  (*f t - structure to hold pertinent data for the app (currently just t_ns_app...) *)
  type t = {
      app : t_ns_app;
    }

  (*f create handle:'a - create a Cocoa application with the opaque handle *)
  let create app_id = {
      app = _NSApplication app_id;
    }

  (*f create window: (rect hint) -> t -> 'b -> t_ns_window, create a window in the application with the opaque window handle *)
  let create_window ?rect:(rect=(0.,0.,640.,480.)) t window_id =
    _NSWindow_create t.app window_id rect

  (*f debug_window 'b:t_ns_window -> unit; NSLog some stuff *)
  let debug_window w =
    _NSWindow_debug w

  (*f set_callback_create t -> t_ns_app_create option -> unit; set the callback to be called on create (first step of run) *)
  let set_callback_create t opt_cb =
    _NSApplication_set_callback_create t.app opt_cb

  (*f set_callback_create t -> t_ns_app_create option -> unit; set the callback to be called on reshape/draw events *)
  let set_callback_reshape_draw t opt_cb =
    _NSApplication_set_callback_reshape_draw t.app opt_cb

  (*f set_callback_handle_key t -> t_ns_app_handle_key option -> unit; set the callback to be called on keyboard *)
  let set_callback_handle_key t opt_cb =
    _NSApplication_set_callback_handle_key t.app opt_cb

  (*f set_callback_handle_mouse t -> t_ns_app_handle_mouse option -> unit; set the callback to be called on mouse events *)
  let set_callback_handle_mouse t opt_cb =
    _NSApplication_set_callback_handle_mouse t.app opt_cb

  (*f set_callback_destroy t -> t_ns_app_destroy option -> unit; set the callback to be called on destroy (last step of run) *)
  let set_callback_destroy t opt_cb =
    _NSApplication_set_callback_destroy t.app opt_cb

  (*f run t -> unit; run the application, from hence OCAML will only run from callbacks *)
  let run t =
    _NSApplication_run t.app
                       
end
