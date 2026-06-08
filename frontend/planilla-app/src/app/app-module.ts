import { NgModule, provideBrowserGlobalErrorListeners } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouterModule } from '@angular/router';

import { routes } from './app-routing-module';
import { App } from './app';
import { Login } from './login/login';

@NgModule({
  imports: [BrowserModule, RouterModule.forRoot(routes), Login],
  providers: [provideBrowserGlobalErrorListeners()],
  bootstrap: [App],
})
export class AppModule {}
