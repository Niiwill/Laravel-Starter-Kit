<?php

declare(strict_types=1);

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Index route for API
Route::middleware('verify-okta')->get('/', function (Request $request) {

    // Get authenticated user from the request
    $user = $request->user();

    return response()->json(['message' => 'Welcome to the API!', 'user' => $user->email]);

    // return response()->json(['message' => 'Welcome to the API!']);
});
