import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ListaEmpleados } from './lista-empleados';

describe('ListaEmpleados', () => {
  let component: ListaEmpleados;
  let fixture: ComponentFixture<ListaEmpleados>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ListaEmpleados],
    }).compileComponents();

    fixture = TestBed.createComponent(ListaEmpleados);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
