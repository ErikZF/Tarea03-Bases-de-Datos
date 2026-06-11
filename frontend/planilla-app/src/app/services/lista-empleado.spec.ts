import { TestBed } from '@angular/core/testing';

import { EmpleadoService } from './lista-empleado';

describe('ListaEmpleado', () => {
  let service: EmpleadoService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(EmpleadoService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
