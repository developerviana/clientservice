import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';

// PO-UI Modules
import { PoModule } from '@po-ui/ng-components';
import { PoTemplatesModule } from '@po-ui/ng-templates';

// Components
import { ClienteEnderecoComponent } from './cliente-endereco.component';

// Services
import { ClienteEnderecoService } from './cliente-endereco.service';

@NgModule({
  declarations: [
    ClienteEnderecoComponent
  ],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    HttpClientModule,
    PoModule,
    PoTemplatesModule
  ],
  providers: [
    ClienteEnderecoService
  ],
  exports: [
    ClienteEnderecoComponent
  ]
})
export class ClienteEnderecoModule { }
