import { compareSync, hashSync } from "bcryptjs";

export class HashService {
  private _salt!: string;

  constructor(salt: string) {
    this._salt = salt;
  }

  //encrypt
  encrypt(plainText: string): string {
    return hashSync(plainText, this._salt);
  }

  //compare
  compare(plainTextString: string, hashed: string): boolean {
    return compareSync(plainTextString, hashed);
  }
}
