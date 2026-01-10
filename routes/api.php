<?php

declare(strict_types=1);

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PaymentController;
use App\Http\Middleware\VerifyOktaToken;


// Index route for API
Route::middleware(VerifyOktaToken::class)->get('/', function (Request $request) {

    // Get authenticated user from the request
    $user = $request->user();

    return response()->json(['message' => 'Welcome to the API!', 'user' => $user->email]);

    // return response()->json(['message' => 'Welcome to the API!']);
});


// Index route for API
Route::get('/pay', [PaymentController::class, 'pay']);

